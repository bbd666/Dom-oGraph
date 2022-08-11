unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, ComCtrls, math,
  Menus, StdCtrls, TAGraph, TASeries, TATransformations, TAIntervalSources,DateUtils,
  TAChartUtils, TADbSource, TASources, TAFuncSeries, TAExpressionSeries , TACustomSource;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    Chart1: TChart;
    BarGraph: TBarSeries;
    Chart2: TChart;
    Chart3: TChart;
    colorsource: TListChartSource;
    Label3: TLabel;
    lbldecim: TEdit;
    map: TColorMapSeries;
    Label2: TLabel;
    laeqt_lbl: TLabeledEdit;
    GroupBox1: TGroupBox;
    duree_lbl: TLabeledEdit;
    dose_lbl: TLabeledEdit;
    laeq: TLineSeries;
    current_leq: TLabeledEdit;
    current_laeq: TLabeledEdit;
    DateTimeIntervalChartSource1: TDateTimeIntervalChartSource;
    Label1: TLabel;
    ListChartSource1: TListChartSource;
    Panel1: TPanel;
    Panel2: TPanel;
    ScrollBar1: TScrollBar;
    spot: TLineSeries;
    CheckBox2: TCheckBox;
    CheckBox3: TCheckBox;
    leq: TLineSeries;
    ChartAxisTransformations1: TChartAxisTransformations;
    ChartAxisTransformations1LogarithmAxisTransform1: TLogarithmAxisTransform;
    CheckBox1: TCheckBox;

    Image1: TImage;
    LabeledEdit1: TLabeledEdit;
    current_time: TLabeledEdit;
    OpenDialog1: TOpenDialog;
    Sel_spectre: TScrollBar;
    StatusBar1: TStatusBar;
    Timer1: TTimer;
    procedure Button1Click(Sender: TObject);
    procedure CheckBox1Click(Sender: TObject);
    procedure CheckBox2Click(Sender: TObject);
    procedure CheckBox3Change(Sender: TObject);
    function colorsourceCompare(AItem1, AItem2: Pointer): Integer;
    procedure FormCreate(Sender: TObject);
    procedure Image2Click(Sender: TObject);
     procedure LabeledEdit1DblClick(Sender: TObject);
    procedure LabeledEdit1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure mapCalculate(const AX, AY: Double; out AZ: Double);
    procedure MenuItem1Click(Sender: TObject);
    procedure MenuItem2Click(Sender: TObject);
    procedure ScrollBar1Change(Sender: TObject);
    procedure Sel_spectreChange(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure Load(Sender: TObject);
    procedure PopulateColorSource;

  private

  public

  end;

var
  Form1: TForm1;
  spectres:array of array of real;
  Temps_traitement,Niveau,niveau_laeq: array of real;
  Fich, Fichout: TextFile;
  Temps  :array of integer;
  tiers_octave,pond:array[0..20] of real;
  nowtime:tdatetime;
  maxnoise,laeqt,duree, step:real;
  scalex:real;

implementation

{$R *.lfm}

{ TForm1 }





procedure TForm1.LabeledEdit1DblClick(Sender: TObject);
begin
    if OpenDialog1.Execute then
    begin
         LabeledEdit1.Text:=OpenDialog1.filename;
         load(self);
    end;
end;

procedure TForm1.LabeledEdit1KeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
const VK_RETURN = 13;
begin
    if (key=VK_RETURN) and  (FileExists(LabeledEdit1.Text)) Then  load(self);
end;

procedure TForm1.PopulateColorSource;
const
  DUMMY = 0.0;
  fullscale =100.;
begin
  with ColorSource do begin
    Add(0.2*fullscale, DUMMY, '', clBlue);      // 0.0 --> blue
    Add(0.3*fullscale, DUMMY, '', clRed);       // 0.3 --> red
    Add(fullscale, DUMMY, '', clYellow);    // 1.0 --> yellow
  end;
end;

procedure TForm1.mapCalculate(const AX, AY: Double; out AZ: Double);
var
  ext: TDoubleRect;
  vx,vy:real;
  indx,indy:integer;
begin
  ext := Chart3.GetFullExtent;
  if length(spectres[0])>0 then
  begin
       vx:=(AX - ext.a.x) /(ext.b.x - ext.a.x)*scalex;
       vy:=(AY - ext.a.y) /(ext.b.y - ext.a.y)*20;
       indx:=min(round(vx),trunc(scalex));
       indy:=min(round(vy),20);
       indx:=max(indx,0);
       indy:=max(indy,0);
       indy:=round(ay);
       indx:=round(ax);
       if  (indx< scalex) and (indy<20) and (indx>=0) and (indy>=0) then
       AZ:=spectres[indy,round(indx*length(spectres[0])/scalex)];
   end;
end;

procedure TForm1.Load(Sender: TObject);
var
   ligne: string;
   a:tstringlist;
   i:integer;
begin
    a:=tstringlist.create;
    a.Delimiter:=' ';
         try
            Laeqt:=0;
            duree:=0;
            Maxnoise:=0;
            AssignFile(Fich,LabeledEdit1.Text);
            Reset(Fich);
            readln(Fich,ligne);
            SetLength(Temps,0);
            SetLength(niveau,0);
            SetLength(niveau_laeq,0);
            spectres:=nil;
            SetLength(spectres,21);
            while not eof(Fich) do
            begin
               readln(Fich,ligne);
               a.DelimitedText:=ligne;
               SetLength(Temps,length(Temps)+1);
               SetLength(Temps_traitement,length(Temps_traitement)+1);
               SetLength(niveau,length(niveau)+1);
               SetLength(niveau_laeq,length(niveau_laeq)+1);
               Temps[length(Temps)-1]:=strtoint(a[a.count-24]);
               Temps_traitement[length(Temps_traitement)-1]:=strtofloat(a[a.count-2]);
               niveau[length(niveau)-1]:=strtofloat(a[a.count-1]);
               niveau_laeq[length(niveau_laeq)-1]:= 0;
               for i:=0 to 20 do
               begin
                  SetLength(spectres[i],length(spectres[i])+1);
                  spectres[i,length(spectres[i])-1]:=strtofloat(a[a.count-23+i]);
                  if   spectres[i,length(spectres[i])-1]> maxnoise then maxnoise:=spectres[i,length(spectres[i])-1];
                  Chart1.Extent.YMax:=maxnoise;
                  Chart1.Extent.YMin:=0;
                  niveau_laeq[length(niveau_laeq)-1]:=niveau_laeq[length(niveau_laeq)-1]+ exp((spectres[i,length(spectres[i])-1]+pond[i]) *ln(10)/10);
               end;
               niveau_laeq[length(niveau_laeq)-1]:=10*ln(niveau_laeq[length(niveau_laeq)-1])/ln(10);
               if length(Temps)>1 then step:= Temps[length(Temps)-1]-Temps[length(Temps)-2] else step:= Temps[length(Temps)-1];
               laeqt:=laeqt+ exp(0.1*niveau_laeq[length(niveau_laeq)-1]*ln(10))*step/1000/3600;
               duree:=duree+step;
            end;
            duree:=duree/1000/3600;
            laeqt:=10*ln(laeqt/duree)/ln(10);
            closefile(Fich);
            Reset(Fich);
            readln(Fich,ligne);
            readln(Fich,ligne);
            a.DelimitedText:=ligne;
            nowtime:=StrToTime(a[1]);
            current_time.text:=TimeToStr(nowtime);
            closefile(Fich);
            Sel_spectre.Max:=length(spectres[0])-1;
            chart1.visible:=true;
            chart2.visible:=true;
            chart3.visible:=true;
            panel1.visible:=true;
            groupbox1.visible:=true;
            sel_spectre.visible:=true;
            current_time.visible:=true;
            current_laeq.visible:=true;
            current_leq.visible:=true;
            laeqt_lbl.visible:=true;
            duree_lbl.visible:=true;
            label2.visible:=true;
            dose_lbl.visible:=true;
            panel2.visible:=true;
            Bargraph.Clear;
            leq.Clear;
            laeq.Clear;
            spot.Clear;
            scalex:=length(spectres[0])-1;
            scalex:=Temps[length(spectres[0])-1]/1000;
            Chart3.AxisList.BottomAxis.Range.Min:=0;
            Chart3.AxisList.BottomAxis.Range.Max:=trunc(scalex);

            for i:=0 to 20 do Bargraph.addxy(ln(tiers_octave[i])/ln(10),spectres[i,sel_spectre.Position]);
            for i:=0 to Sel_spectre.Max-1 do leq.addxy(Temps[i]/1000,niveau[i]);
            for i:=0 to Sel_spectre.Max-1 do laeq.addxy(Temps[i]/1000,niveau_laeq[i]);

            spot.AddXY(nowtime,0);
            spot.AddXY(nowtime,100);
         finally
         end;
    a.free;
end;





procedure TForm1.FormCreate(Sender: TObject);
var
   i:integer;
begin
    i:=0;
    tiers_octave[i]:=100;
    i:=i+1;tiers_octave[i]:=125;
    i:=i+1;tiers_octave[i]:=160;
    i:=i+1;tiers_octave[i]:=200;
    i:=i+1;tiers_octave[i]:=250;
    i:=i+1;tiers_octave[i]:=315;
    i:=i+1;tiers_octave[i]:=400;
    i:=i+1;tiers_octave[i]:=500;
    i:=i+1;tiers_octave[i]:=630;
    i:=i+1;tiers_octave[i]:=800;
    i:=i+1;tiers_octave[i]:=1000;
    i:=i+1;tiers_octave[i]:=1250;
    i:=i+1;tiers_octave[i]:=1600;
    i:=i+1;tiers_octave[i]:=2000;
    i:=i+1;tiers_octave[i]:=2500;
    i:=i+1;tiers_octave[i]:=3150;
    i:=i+1;tiers_octave[i]:=4000;
    i:=i+1;tiers_octave[i]:=5000;
    i:=i+1;tiers_octave[i]:=6300;
    i:=i+1;tiers_octave[i]:=8000;
    i:=i+1;tiers_octave[i]:=10000;

    i:=0;
    pond[i]:=-19;
    i:=i+1;pond[i]:=-16;
    i:=i+1;pond[i]:=-13;
    i:=i+1;pond[i]:=-11;
    i:=i+1;pond[i]:=-8.6;
    i:=i+1;pond[i]:=-6.6;
    i:=i+1;pond[i]:=-4.8;
    i:=i+1;pond[i]:=-3.2;
    i:=i+1;pond[i]:=-1.9;
    i:=i+1;pond[i]:=-0.8;
    i:=i+1;pond[i]:=0;
    i:=i+1;pond[i]:=0.6;
    i:=i+1;pond[i]:=1;
    i:=i+1;pond[i]:=1.2;
    i:=i+1;pond[i]:=1.3;
    i:=i+1;pond[i]:=1.2;
    i:=i+1;pond[i]:=1;
    i:=i+1;pond[i]:=0.5;
    i:=i+1;pond[i]:=-0.1;
    i:=i+1;pond[i]:=-1.1;
    i:=i+1;pond[i]:=-2.5;

    SetLength(spectres,21);
    PopulateColorSource;

end;

procedure TForm1.Image2Click(Sender: TObject);
begin

end;



procedure TForm1.CheckBox1Click(Sender: TObject);
begin
  if checkbox1.checked then bargraph.Marks.style:=smslabelvalue else bargraph.Marks.style:=smsnone;
end;

procedure TForm1.Button1Click(Sender: TObject);
var
   i:integer;
   r:integer;
   ligne:string;
begin
  try
    r:=strtoint(lbldecim.text);
  except
    r:=1;
  end;
  AssignFile(Fich,LabeledEdit1.Text);
  AssignFile(Fichout,'Out.Text');
  Reset(Fich);
  Rewrite(Fichout);
  readln(Fich,ligne);
  writeln(Fichout,ligne);
  readln(Fich,ligne);
  writeln(Fichout,ligne);
  i:=1;
  while not eof(Fich) do
  begin
   readln(Fich,ligne);
   if i mod  r =0 then      writeln(Fichout,ligne);
   inc(i);
  end;
  Closefile(Fich);
  Closefile(Fichout);
end;



procedure TForm1.CheckBox2Click(Sender: TObject);
begin
  if checkbox2.checked then
  begin
       Chart1.Extent.UseYMax := true;
       Chart1.Extent.UseYMin := true;
  end
  else
  begin
       Chart1.Extent.UseYMax := false;
       Chart1.Extent.UseYMin := false;
  end;
end;

procedure TForm1.CheckBox3Change(Sender: TObject);
begin
  if checkbox3.checked then timer1.Enabled:=true else timer1.Enabled:=false;
end;

function TForm1.colorsourceCompare(AItem1, AItem2: Pointer): Integer;
begin

end;

procedure TForm1.MenuItem1Click(Sender: TObject);
begin

end;

procedure TForm1.MenuItem2Click(Sender: TObject);
begin

end;

procedure TForm1.ScrollBar1Change(Sender: TObject);
begin
  timer1.Interval:=ScrollBar1.position;
end;

procedure TForm1.Sel_spectreChange(Sender: TObject);
var
   i:integer;
begin
  Bargraph.Clear;
  for i:=0 to 20 do Bargraph.addxy(ln(tiers_octave[i])/ln(10),spectres[i,sel_spectre.Position]);
  current_time.text:=TimeToStr(IncMilliSecond(nowtime,Temps[sel_spectre.Position]));
  current_leq.text:=floattostr(niveau[sel_spectre.Position]);
  current_laeq.text:=floattostrf(niveau_laeq[sel_spectre.Position],fffixed,5,2);
  laeqt_lbl.text:=floattostrf(laeqt,fffixed,5,2);
  duree_lbl.text:=floattostrf(duree,fffixed,5,2);
  dose_lbl.text:=floattostrf(laeqt+10*ln(duree/8)/ln(10),fffixed,5,2);
  //spot.XValue[0]:=IncMilliSecond(nowtime,Temps[sel_spectre.Position]);
  //spot.xvalue[1]:=IncMilliSecond(nowtime,Temps[sel_spectre.Position]);
  spot.XValue[0]:=Temps[sel_spectre.Position]/1000;
  spot.xvalue[1]:=Temps[sel_spectre.Position]/1000;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  if sel_spectre.Position=sel_spectre.max then  sel_spectre.Position:=0 else sel_spectre.Position:=sel_spectre.Position+1;
end;



end.

