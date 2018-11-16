//+------------------------------------------------------------------+
//|                                                        trend.mq5 |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
CTrade trade;
CPositionInfo positioninfo;

input bool enable_A1=true;
input bool enable_A2=true;
input bool enable_B1=true;
input bool enable_B2=true;
input bool enable_B3=true;
input bool enable_B0=true;

input bool huangjin=false;
input bool yuanyou=false;

int FirstBar=1;
int DeltaBar=12;
bool InsLine=true;
int DimMaxPos=150;
color  clrSup= 0xFF0000; 
color  clrRes= 0x0000FF; 


double vol_now;

color     ColorTL_U   =  clrBlue,
          ColorTL_D   =  clrRed,
          ColorCH_U   =  clrBlue,
          ColorCH_D   =  clrRed,
          ColorTR_U   =  clrGreen,
          ColorTR_D   =  clrViolet;
string    NameTL_U    =  "Up_", 
          NameTL_D    =  "Dn_",
          NameCH_U    =  "UpZ_", 
          NameCH_D    =  "DnZ_",
          NameTR_U    =  "UpTr_", 
          NameTR_D    =  "DnTr_";
int       last_bar    =  0,
          cntLine     =  1,       
          Line_U[100][2],      
          Line_D[100][2],     
          LineI_U[100][2],     
          LineI_D[100][2],      
          LineShow_U[100][4],   
          LineShow_D[100][4];
          //1 0记录位置，1在前，2记录bar2就是虚线通道连的点，3记录这个通道是否可用（刨除那种在中间不囊括后面K线的通道),0代表不可用
          
int       tlines_U=0,
          tlines_D=0;
string    zig="zig";
double deviation=5*_Point;
double    d_point=_Point;

double temp_High,temp_Low;
int HighP[200],LowP[200];
int Hnum_M1=0,Lnum_M1=0;
int LineHP_M1_1[200],LineHP_M1_2[200],LineLP_M1_1[200],LineLP_M1_2[200];

int Hnum_M5=0,Lnum_M5=0;
int LineHP_M5_1[100],LineHP_M5_2[100],LineLP_M5_1[100],LineLP_M5_2[100];

int Hnum_M15=0,Lnum_M15=0;
int LineHP_M15_1[50],LineHP_M15_2[50],LineLP_M15_1[50],LineLP_M15_2[50];

int Hnum_H1=0,Lnum_H1=0;
int LineHP_H1_1[50],LineHP_H1_2[50],LineLP_H1_1[50],LineLP_H1_2[50];

int    barsnum_M1;
int    barsnum_M5;
int    barsnum_M15;
int    barsnum_M30;
int    barsnum_H1;
int    barsnum_H4;
int    barsnum_D1;

double High_M1[1000000];
double Low_M1[1000000];
datetime Time_M1[1000000];

int ZigZagBuffer_num_M1;

double  ZigZagBuffer_M1[1000000];
double  HighMapBuffer_M1[1000000];
double  LowMapBuffer_M1[1000000];
int     ZigZagBuffer_pos_M1[100];

double High_M5[500000];
double Low_M5[500000];
double Open_M5[500000];
double Close_M5[500000];
datetime Time_M5[500000];

int ZigZagBuffer_num_M5;

double  ZigZagBuffer_M5[500000];
double  HighMapBuffer_M5[500000];
double  LowMapBuffer_M5[500000];
int     ZigZagBuffer_pos_M5[100];

double FRAH_M5[500000];
double FRAL_M5[500000];
int    FRAH_M5_pos[200];
int    FRAL_M5_pos[200];

double High_M15[200000];
double Low_M15[200000];
datetime Time_M15[200000];

int ZigZagBuffer_num_M15;

double  ZigZagBuffer_M15[200000];
double  HighMapBuffer_M15[200000];
double  LowMapBuffer_M15[200000];
int     ZigZagBuffer_pos_M15[100];

double High_M30[150000];
double Low_M30[150000];
datetime Time_M30[150000];

int ZigZagBuffer_num_M30;

double  ZigZagBuffer_M30[150000];
double  HighMapBuffer_M30[150000];
double  LowMapBuffer_M30[150000];
int     ZigZagBuffer_pos_M30[100];

double High_H1[100000];
double Low_H1[100000];
datetime Time_H1[100000];

int ZigZagBuffer_num_H1;

double  ZigZagBuffer_H1[100000];
double  HighMapBuffer_H1[100000];
double  LowMapBuffer_H1[100000];
int     ZigZagBuffer_pos_H1[100];

double High_H4[50000];
double Low_H4[50000];
datetime Time_H4[50000];

int ZigZagBuffer_num_H4;

double  ZigZagBuffer_H4[50000];
double  HighMapBuffer_H4[50000];
double  LowMapBuffer_H4[50000];
int     ZigZagBuffer_pos_H4[100];


double High_D1[10000];
double Low_D1[10000];
datetime Time_D1[10000];

int ZigZagBuffer_num_D1;

double  ZigZagBuffer_D1[10000];
double  HighMapBuffer_D1[10000];
double  LowMapBuffer_D1[10000];
int     ZigZagBuffer_pos_D1[100];


double UpFractal[500000];
double DnFractal[500000];



void fsell(double sl,double vol)
{
     MqlTradeRequest Request;
     ZeroMemory(Request);
     Request.action=TRADE_ACTION_DEAL;
     Request.symbol=_Symbol;
     Request.volume=vol;
     Request.price=NormalizeDouble(SymbolInfoDouble(Symbol(),SYMBOL_BID),_Digits);
     Request.type=ORDER_TYPE_SELL;
     Request.type_filling=ORDER_FILLING_FOK;
     Request.sl=sl;
	 Request.magic=888;
     MqlTradeResult Result;
     ZeroMemory(Result);
     bool result=OrderSend(Request,Result);
     //if(result==false)Alert("Incorrect Request");
     //else Alert("Result Code: ",Result.retcode,", ","Deal: ",Result.deal,", ","Volume: ",Result.volume);
}

void fbuy(double sl,double vol)
{
     MqlTradeRequest Request;
     ZeroMemory(Request);
     Request.action=TRADE_ACTION_DEAL;
     Request.symbol=_Symbol;
     Request.volume=vol;
     Request.price=NormalizeDouble(SymbolInfoDouble(Symbol(),SYMBOL_ASK),_Digits);
     Request.type=ORDER_TYPE_BUY;
     Request.type_filling=ORDER_FILLING_FOK;
     Request.sl=sl;
	 Request.magic=888;
     MqlTradeResult Result;
     ZeroMemory(Result);
     bool result=OrderSend(Request,Result);
     //if(result==false)Alert("Incorrect Request");
     //else Alert("Result Code: ",Result.retcode,", ","Deal: ",Result.deal,", ","Volume: ",Result.volume);
}

void close_sell()//所挂的图表的品种的空单仓位全平掉
{
     int position_num=PositionsTotal();
     ulong position_ticket;
     int position_i=position_num;
     while(position_i>0)
     {
        position_ticket=PositionGetTicket(position_i-1);//这是仓位的ticket
        positioninfo.SelectByTicket(position_ticket);
        if((positioninfo.Symbol()==_Symbol)&&(positioninfo.PositionType()==POSITION_TYPE_SELL))
        {
           trade.PositionClose(position_ticket);
        }
        position_i--;
     }
}

void closeby_sell()//所挂的图表的品种的空单仓位出一半
{
     int position_num=PositionsTotal();
     ulong position_ticket,position_ticket1=0,position_ticket2=0;
     int position_i=position_num;
     double vol_buy=0,vol_sell=0;
     int flag_buy=0,flag_sell=0;
     while(position_i>0)
     {
        position_ticket=PositionGetTicket(position_i-1);//这是仓位的ticket
        positioninfo.SelectByTicket(position_ticket);
        if((positioninfo.Symbol()==_Symbol)&&(positioninfo.PositionType()==POSITION_TYPE_BUY))
        {
            position_ticket1=PositionGetTicket(position_i-1);//这是多单的ticket
            vol_buy=positioninfo.Volume();
            flag_buy=1;
        }
        if((positioninfo.Symbol()==_Symbol)&&(positioninfo.PositionType()==POSITION_TYPE_SELL))
        {
            position_ticket2=PositionGetTicket(position_i-1);//这是空单的ticket
            vol_sell=positioninfo.Volume();
            flag_sell=1;
        }
        position_i--;
     }
     if((vol_sell>=vol_buy)&&(flag_buy==1)&&(flag_sell==1))
     {
         trade.PositionCloseBy(position_ticket2,position_ticket1);
     }
}

void close_buy()//所挂的图表的品种的多单仓位全平掉
{
     int position_num=PositionsTotal();
     ulong position_ticket;
     int position_i=position_num;
     while(position_i>0)
     {
        position_ticket=PositionGetTicket(position_i-1);//这是仓位的ticket
        positioninfo.SelectByTicket(position_ticket);
        if((positioninfo.Symbol()==_Symbol)&&(positioninfo.PositionType()==POSITION_TYPE_BUY))
        {
           trade.PositionClose(position_ticket);
        }
        position_i--;
     }
}

void closeby_buy()//所挂的图表的品种的多单仓位出一半
{
     int position_num=PositionsTotal();
     ulong position_ticket,position_ticket1=0,position_ticket2=0;
     int position_i=position_num;
     double vol_buy=0,vol_sell=0;
     int flag_buy=0,flag_sell=0;
     while(position_i>0)
     {
        position_ticket=PositionGetTicket(position_i-1);//这是仓位的ticket
        positioninfo.SelectByTicket(position_ticket);
        if((positioninfo.Symbol()==_Symbol)&&(positioninfo.PositionType()==POSITION_TYPE_BUY))
        {
            position_ticket1=PositionGetTicket(position_i-1);//这是多单的ticket
            vol_buy=positioninfo.Volume();
            flag_buy=1;
        }
        if((positioninfo.Symbol()==_Symbol)&&(positioninfo.PositionType()==POSITION_TYPE_SELL))
        {
            position_ticket2=PositionGetTicket(position_i-1);//这是空单的ticket
            vol_sell=positioninfo.Volume();
            flag_sell=1;
        }
        position_i--;
     }
     if((vol_sell<=vol_buy)&&(flag_buy==1)&&(flag_sell==1))
     {
         trade.PositionCloseBy(position_ticket1,position_ticket2);
     }
}

void copy()
{
     //datetime begin = TimeCurrent() - 60*60*24*60;
     barsnum_M1=Bars(_Symbol,PERIOD_M1);
     barsnum_M5=Bars(_Symbol,PERIOD_M5);
     barsnum_M15=Bars(_Symbol,PERIOD_M15);
     barsnum_M30=Bars(_Symbol,PERIOD_M30);
     barsnum_H1=Bars(_Symbol,PERIOD_H1);
     barsnum_H4=Bars(_Symbol,PERIOD_H4);
     barsnum_D1=Bars(_Symbol,PERIOD_D1);
     
     barsnum_M1= (barsnum_M1==0 || barsnum_M1 > 100000)?100000:barsnum_M1;
     barsnum_M5=(barsnum_M5==0|| barsnum_M5 > 100000)?100000:barsnum_M5;
     barsnum_M15=(barsnum_M15==0 || barsnum_M15 > 100000)?100000:barsnum_M15;
     barsnum_M30=(barsnum_M30==0 || barsnum_M30 > 100000)?100000:barsnum_M30;
     barsnum_H1=(barsnum_H1==0 || barsnum_H1 > 100000)?100000:barsnum_H1;
     barsnum_H4=(barsnum_H4==0 || barsnum_H4 > 50000)?50000:barsnum_H4;
     barsnum_D1=(barsnum_D1==0 || barsnum_D1 > 10000)?10000:barsnum_D1;
     //Print("多单symbol: ",_Symbol,"H4: ",barsnum_H4," D1 ",barsnum_D1," h1: ",barsnum_H1);
     
     CopyHigh(_Symbol,PERIOD_M1,0,barsnum_M1,High_M1);
     CopyLow(_Symbol,PERIOD_M1,0,barsnum_M1,Low_M1);
     CopyTime(_Symbol,PERIOD_M1,0,barsnum_M1,Time_M1);
     
     CopyHigh(_Symbol,PERIOD_M5,0,barsnum_M5,High_M5);
     CopyLow(_Symbol,PERIOD_M5,0,barsnum_M5,Low_M5);
     CopyTime(_Symbol,PERIOD_M5,0,barsnum_M5,Time_M5);
     CopyOpen(_Symbol,PERIOD_M5,0,barsnum_M5,Open_M5);
     CopyClose(_Symbol,PERIOD_M5,0,barsnum_M5,Close_M5);
     
     CopyHigh(_Symbol,PERIOD_M15,0,barsnum_M15,High_M15);
     CopyLow(_Symbol,PERIOD_M15,0,barsnum_M15,Low_M15);
     CopyTime(_Symbol,PERIOD_M15,0,barsnum_M15,Time_M15);
     
     CopyHigh(_Symbol,PERIOD_M30,0,barsnum_M30,High_M30);
     CopyLow(_Symbol,PERIOD_M30,0,barsnum_M30,Low_M30);
     CopyTime(_Symbol,PERIOD_M30,0,barsnum_M30,Time_M30);
     
     CopyHigh(_Symbol,PERIOD_H1,0,barsnum_H1,High_H1);
     CopyLow(_Symbol,PERIOD_H1,0,barsnum_H1,Low_H1);
     CopyTime(_Symbol,PERIOD_H1,0,barsnum_H1,Time_H1);
     
     CopyHigh(_Symbol,PERIOD_H4,0,barsnum_H4,High_H4);
     CopyLow(_Symbol,PERIOD_H4,0,barsnum_H4,Low_H4);
     CopyTime(_Symbol,PERIOD_H4,0,barsnum_H4,Time_H4);
     
     CopyHigh(_Symbol,PERIOD_D1,0,barsnum_D1,High_D1);
     CopyLow(_Symbol,PERIOD_D1,0,barsnum_D1,Low_D1);
     CopyTime(_Symbol,PERIOD_D1,0,barsnum_D1,Time_D1);
}

void advance(double &High[],double &Low[],int barsnum)
{
     int i;
     
     if(barsnum-300 <=0)
     {
      Print("advance: ",barsnum);
      return;
     }
     for(i=barsnum-300;i<barsnum;i++)
     {
         if(High[i]>temp_High) HighP[0]=i;
         else New_HighPoint();
         temp_High=High[i];
         if(Low[i]<temp_Low) LowP[0]=i;
         else New_LowPoint();
         temp_Low=Low[i];
     }
}

void trend(double &High[],double &Low[],datetime &Time[],
           int &LineHP_1[],int &LineHP_2[],
           int &LineLP_1[],int &LineLP_2[],
           int &Hnum,int &Lnum)
{
     int StartP_1,StartP_2;
     int P_1,P_2;
     int i;
     bool flag;
     int dis;
     double div,lineP;
     string sName;
     StartP_1=(3*DimMaxPos)/4;
     Hnum=0;
     ObjectsDeleteAll(0,0,OBJ_TREND);
     for(P_1=StartP_1;P_1>2;P_1--)
     {
         for(P_2=P_1-1;P_2>1;P_2--)
         {
             dis=HighP[P_2]-HighP[P_1];
             if(dis<=6)continue;
             div=High[HighP[P_2]]-High[HighP[P_1]];
             flag=true;
             StartP_2=(DimMaxPos+2*P_1)/3;
             for(i=StartP_2;i>1;i--)
             {
                 lineP=div*(HighP[i]-HighP[P_1])/dis+High[HighP[P_1]];
                 if(lineP<High[HighP[i]]){flag=false;break;}
             }
             if(flag)
             {
                if((HighP[P_1]!=LineHP_1[Hnum])||(HighP[P_2]!=LineHP_2[Hnum]))
                {
                   Hnum++;
                   LineHP_1[Hnum]=HighP[P_1];
                   LineHP_2[Hnum]=HighP[P_2];
                }
                /*sName="R"+IntegerToString(P_1,0,' ')+IntegerToString(P_2,0,' ');
                ObjectCreate(0,sName,OBJ_TREND,0,Time[HighP[P_1]],High[HighP[P_1]],Time[HighP[P_2]],High[HighP[P_2]]);
                ObjectSetInteger(0,sName,OBJPROP_RAY_RIGHT,true);
                ObjectSetInteger(0,sName,OBJPROP_COLOR,clrGreen);*/
             }
         }
     }
     Lnum=0;
     StartP_1=(3*DimMaxPos)/4;
     for(P_1=StartP_1;P_1>2;P_1--)
     {
         for(P_2=P_1-1;P_2>1;P_2--)
         {
             dis=LowP[P_2]-LowP[P_1];
             if(dis<10)continue;
             div=Low[LowP[P_2]]-Low[LowP[P_1]];
             flag=true;
             StartP_2=(DimMaxPos+2*P_1)/3;
             for(i=StartP_2;i>1;i--)
             {
                 lineP=div*(LowP[i]-LowP[P_1])/dis+Low[LowP[P_1]];
                 if(lineP>Low[LowP[i]]){flag=false;break;}
             }
             if(flag)
             {
                if((LowP[P_1]!=LineLP_1[Lnum])||(LowP[P_2]!=LineLP_2[Lnum]))
                {
                   Lnum++;
                   LineLP_1[Lnum]=LowP[P_1];
                   LineLP_2[Lnum]=LowP[P_2];
                }
                /*sName="R"+IntegerToString(P_1,0,' ')+IntegerToString(P_2,0,' ');
                ObjectCreate(0,sName,OBJ_TREND,0,Time[LowP[P_1]],Low[LowP[P_1]],Time[LowP[P_2]],Low[LowP[P_2]]);
                ObjectSetInteger(0,sName,OBJPROP_RAY_RIGHT,true);
                ObjectSetInteger(0,sName,OBJPROP_COLOR,clrPink);*/
             }
         }
     }
     
}

void New_HighPoint()
{
     int i;
     for(i=DimMaxPos;i>0;i--)
         HighP[i]=HighP[i-1];
}

void New_LowPoint()
{
     int i;
     for(i=DimMaxPos;i>0;i--)
         LowP[i]=LowP[i-1];
}

void Draw_TL()
{
     int i,j,
         MaxTL,Bar2;
     double Bar1_Value,
            Bar2_Value,
            Bar0_Value;
     //DeleteTrendLine( NameTL_U, 100);
     //DeleteTrendLine( NameTL_D, 100);
     //DeleteTrendLine( NameCH_U, 100);
     //DeleteTrendLine( NameCH_D, 100);
     //DeleteTrendLine( NameTR_U, 100);
     //DeleteTrendLine( NameTR_D, 100);
     int U_first=barsnum_M1-1,
         D_first=barsnum_M1-1;
     
     for(i=barsnum_M1-2;;i--)//蓝线起始尾部处理
     {
         if(Low_M1[i]>Low_M1[i-1])
         {
            U_first=i-1;
            break;
         }
     }
     /*for(i=U_first-1;;i--)
     {
         if(Low_M5[i]>Low_M5[i-1])
         {
            U_first=i-1;
            break;
         }
     }*/
     
     for(i=barsnum_M1-2;;i--)//红线起始尾部处理
     {
         if(High_M1[i]<High_M1[i-1])
         {
            D_first=i-1;
            break;
         }
     }
     /*
     for(i=D_first-1;;i--)//蓝线起始尾部处理
     {
         if(High_M5[i]<High_M5[i-1])
         {
            D_first=i-1;
            break;
         }
     }
     */
     Line_U[0][0]=U_first;
     Line_U[0][1]=FindPoint(Line_U[0][0],barsnum_M1-3000,1);
     Line_D[0][0]=D_first;
     Line_D[0][1]=FindPoint(Line_D[0][0],barsnum_M1-3000,-1);
     
     i=0;
     while((Line_U[i][1]<Line_U[i][0]))
     {
           i++;
           Line_U[i][0]=Line_U[i-1][1];
           Line_U[i][1]=FindPoint(Line_U[i][0],barsnum_M1-3000,1);
     }
     MaxTL=i-1;
     cntLine=0;
     j=0;
     int k;
     for(i=0;i<=MaxTL;i++)
     {
         if(Line_U[i][0]-Line_U[i][1]>=DeltaBar)
         {
            cntLine++;
            LineShow_U[j][0]=Line_U[i][0];
            LineShow_U[j][1]=Line_U[i][1];
            CreateLine(NameTL_U+cntLine,Time_M1[Line_U[i][1]],Low_M1[Line_U[i][1]],Time_M1[Line_U[i][0]],Low_M1[Line_U[i][0]],ColorTL_U,STYLE_SOLID);
            ObjectSetInteger(0,NameTL_U+cntLine,OBJPROP_RAY_RIGHT,true);
            Bar2=DrawLine(NameTL_U+cntLine,Line_U[i][1],Line_U[i][0],1);
            LineShow_U[j][2]=Bar2;
            Bar2_Value=ObjectGetValueByTime(0,NameTL_U+cntLine,Time_M1[Bar2],0);
            Bar0_Value=Low_M1[Line_U[i][0]]+(High_M1[Bar2]-Bar2_Value);
            Bar1_Value=Low_M1[Line_U[i][1]]+(High_M1[Bar2]-Bar2_Value);
            CreateLine(NameCH_U+cntLine,Time_M1[Line_U[i][1]],Bar1_Value,Time_M1[Line_U[i][0]],Bar0_Value,ColorCH_U,STYLE_DASH);
            //ObjectSetInteger(0,NameCH_U+cntLine,OBJPROP_RAY_RIGHT,true);
            for(k=Line_U[i][0]+1;k<barsnum_M1;k++)
            {
                Bar0_Value=ObjectGetValueByTime(0,NameTL_U+cntLine,Time_M1[k],0)+(High_M1[Bar2]-Bar2_Value);
                if(High_M1[k]>Bar0_Value)break;
            }
            if(k<barsnum_M1)LineShow_U[j][3]=0;
            else LineShow_U[j][3]=1;
            j++;
         }
     }
     tlines_U=cntLine;
     
     i=0;
     while((Line_D[i][1]<Line_D[i][0]))
     {
           i++;
           Line_D[i][0]=Line_D[i-1][1];
           Line_D[i][1]=FindPoint(Line_D[i][0],barsnum_M1-3000,-1);
     }
     MaxTL=i-1;
     cntLine=0;
     j=0;
     for(i=0;i<=MaxTL;i++)
     {
         if(Line_D[i][0]-Line_D[i][1]>=DeltaBar)
         {
            cntLine++;
            LineShow_D[j][0]=Line_D[i][0];
            LineShow_D[j][1]=Line_D[i][1];
            CreateLine(NameTL_D+cntLine,Time_M1[Line_D[i][1]],High_M1[Line_D[i][1]],Time_M1[Line_D[i][0]],High_M1[Line_D[i][0]],ColorTL_D,STYLE_SOLID);
            ObjectSetInteger(0,NameTL_D+cntLine,OBJPROP_RAY_RIGHT,true);
            Bar2=DrawLine(NameTL_D+cntLine,Line_D[i][1],Line_D[i][0],-1);
            LineShow_D[j][2]=Bar2;
            Bar2_Value=ObjectGetValueByTime(0,NameTL_D+cntLine,Time_M1[Bar2],0);
            Bar0_Value=High_M1[Line_D[i][0]]-(Bar2_Value-Low_M1[Bar2]);
            Bar1_Value=High_M1[Line_D[i][1]]-(Bar2_Value-Low_M1[Bar2]);
            CreateLine(NameCH_D+cntLine,Time_M1[Line_D[i][1]],Bar1_Value,Time_M1[Line_D[i][0]],Bar0_Value,ColorCH_D,STYLE_DASH);
            //ObjectSetInteger(0,NameCH_D+cntLine,OBJPROP_RAY_RIGHT,true);
            for(k=Line_D[i][0]+1;k<barsnum_M1;k++)
            {
                Bar0_Value=ObjectGetValueByTime(0,NameTL_D+cntLine,Time_M1[k],0)-(Bar2_Value-Low_M1[Bar2]);
                if(Low_M1[k]<Bar0_Value)break;
            }
            if(k<barsnum_M1)LineShow_D[j][3]=0;
            else LineShow_D[j][3]=1;
            j++;
         }
     }
     tlines_D=cntLine;
}

int DrawLine(string NameLine,int StartPoint,int FinPoint,int UpDown)
{
    int i,FinBar;
    double MaxValue=0,TekValue=0;
    FinBar=StartPoint;
    for(i=StartPoint;i<=FinPoint;i++)
    {
        if(UpDown==1)TekValue=High_M1[i]-ObjectGetValueByTime(0,NameLine,Time_M1[i],0);
        else TekValue=ObjectGetValueByTime(0,NameLine,Time_M1[i],0)-Low_M1[i];
        if(TekValue>MaxValue)
        {
           MaxValue=TekValue;
           FinBar=i;
        }
    }
    return(FinBar);
}

int FindPoint(int Bar_1,int Bar_Fin,int Trend)
{
    int Bar_2,
        i;
    double BarValue_1,
           BarValue_2,
           BarValue_i;
    Bar_2=Bar_1;
    for(i=Bar_1-1;i>Bar_Fin;i--)
    {
        if(Trend==1)
        {
           if(Low_M1[i]<Low_M1[Bar_1])
           {
              Bar_2=i;
              break;
           }
        }
        else
        {
            if(High_M1[i]>High_M1[Bar_1])
            {
               Bar_2=i;
               break;
            }
        }
    }
    if(Bar_2<Bar_1)
    {
       int MaxBar=Bar_2;
       double LineFirst;
       if(Trend==1)
       {
          LineFirst=(Low_M1[Bar_1]-Low_M1[Bar_2])/(Bar_1-Bar_2);
          for(i=MaxBar-1;i>0;i--)
          {
              if((Low_M1[Bar_1]-Low_M1[i])/(Bar_1-i)>LineFirst)
              {
                 Bar_2=i;
                 LineFirst=(Low_M1[Bar_1]-Low_M1[Bar_2])/(Bar_1-Bar_2);
              }
          }
       }
       else
       {
           LineFirst=(High_M1[Bar_2]-High_M1[Bar_1])/(Bar_1-Bar_2);
           for(i=MaxBar-1;i>0;i--)
           {
               if((High_M1[i]-High_M1[Bar_1])/(Bar_1-i)>LineFirst)
               {
                  Bar_2=i;
                  LineFirst=(High_M1[Bar_2]-High_M1[Bar_1])/(Bar_1-Bar_2);
               }
           }
       }
    }
    return(Bar_2);
}

bool CreateLine(string Name_Line,datetime X1,double Y1,datetime X2,double Y2,color Color_Line,int Style_Line)
{
     if(!ObjectCreate(0,Name_Line,OBJ_TREND,0,0,0,0,0))return(false);
     ObjectSetInteger(0,Name_Line,OBJPROP_COLOR,Color_Line);
     ObjectSetInteger(0,Name_Line,OBJPROP_STYLE,Style_Line);
     MoveLine(Name_Line,X1,Y1,X2,Y2);
     return(true);
}

void MoveLine(string NameLine,datetime X1,double Y1,datetime X2,double Y2)
{
     ObjectMove(0,NameLine,0,X1,Y1);
     ObjectMove(0,NameLine,1,X2,Y2);
     return;
}

//+------------------------------------------------------------------+
//|  寻找12根柱的最高点                                              |
//+------------------------------------------------------------------+
int iHighest(const double &array[],int depth,int startPos)
{
    int index=startPos;
    if(startPos<0)
    {
       return 0;
    }
    int size=ArraySize(array);
    if(startPos-depth<0)depth=startPos;
    double max=array[startPos];
    int i;
    for(i=startPos;i>startPos-depth;i--)
    {
        if(array[i]>max)
        {
           index=i;
           max=array[i];
        }
    }
    return(index);
}

//+------------------------------------------------------------------+
//|  寻找12根柱的最低点                                              |
//+------------------------------------------------------------------+
int iLowest(const double &array[],int depth,int startPos)
{
    int index=startPos;
    if(startPos<0)
    {
       return 0;
    }
    int size=ArraySize(array);
    if(startPos-depth<0)depth=startPos;
    double min=array[startPos];
    int i;
    for(i=startPos;i>startPos-depth;i--)
    {
        if(array[i]<min)
        {
           index=i;
           min=array[i];
        }
    }
    return(index);
}

int caculate_zig(int start,int &ZigZagBuffer_num,
                 double &ZigZagBuffer[],
                 double &High[],double &Low[],datetime &Time[],
                 double &HighMapBuffer[],double &LowMapBuffer[],
                 int &ZigZagBuffer_pos[],int barsnum)
{
    int i=0,limit=barsnum-start,shift=0;
    
    if(limit <= 0)
    {
      Print("limit = br -start is: ",limit,"  barsum is: ",barsnum);
      return 0;
    }
    int counterZ=0;
    int level=3;
    int whatlookfor=0;
    int lasthighpos=0,lastlowpos=0;
    double curhigh=0,curlow=0,lasthigh=0,lastlow=0;
    double val=0,res=0;
    int back=0;
    /*if(x==0)
    {
       ArrayInitialize(ZigZagBuffer,0.0);
       ArrayInitialize(HighMapBuffer,0.0);
       ArrayInitialize(LowMapBuffer,0.0);
       limit=12;
    }
    if(x>0)//计算过
     {  
        i=barsnum-1;
        while((counterZ<level)&&(i>barsnum-100))
        {
              res=ZigZagBuffer[i];
              if(res!=0)counterZ++;
              i--;
        }
        i++;
        limit=i;
        
        if(LowMapBuffer[i]!=0)
        {
           curlow=LowMapBuffer[i];
           whatlookfor=1;
        }
        else
        {
            curhigh=HighMapBuffer[i];
            whatlookfor=-1;
        }
        
        for(i=limit+1;i<barsnum;i++)
        {
            ZigZagBuffer[i]=0.0;
            LowMapBuffer[i]=0.0;
            HighMapBuffer[i]=0.0;
        }
     }*/
     for(i=limit;i<barsnum;i++)
     {
            ZigZagBuffer[i]=0.0;
            LowMapBuffer[i]=0.0;
            HighMapBuffer[i]=0.0;
     }
     for(shift=limit;shift<barsnum;shift++)
     {
         //寻找低点
         val=Low[iLowest(Low,12,shift)];
         if(val==lastlow)val=0.0;
         else
         {
             lastlow=val;
             if(Low[shift]-val>deviation)val=0.0;
             else
             {
                 for(back=1;back<=3;back++)
                 {
                     int k = shift-back;
                     if(k<=0) return 0;
                     res=LowMapBuffer[k];
                     if((res!=0)&&(res>val))LowMapBuffer[k]=0.0;
                 }
             }
         }
         if(Low[shift]==val)LowMapBuffer[shift]=val;
         else LowMapBuffer[shift]=0.0;
         //寻找高点
         val=High[iHighest(High,12,shift)];
         if(val==lasthigh)val=0.0;
         else
         {
             lasthigh=val;
             if(val-High[shift]>deviation)val=0.0;
             else
             {
                 for(back=1;back<=3;back++)
                 {
                     int k = shift-back;
                     if(k<=0) return 0;
                     res=HighMapBuffer[k];
                     if((res!=0)&&(res<val))HighMapBuffer[k]=0.0;
                 }
             }
         } 
         if(High[shift]==val)HighMapBuffer[shift]=val;
         else HighMapBuffer[shift]=0.0;
     }
     if(whatlookfor==0)
     {
        lastlow=0;
        lasthigh=0;
     }
     else
     {
         lastlow=curlow;
         lasthigh=curhigh;
     }
     for(shift=limit;shift<barsnum;shift++)
     {
         res=0.0;
         switch(whatlookfor)
         {
                case 0:
                       if((lastlow==0)&&(lasthigh==0))
                       {
                          if(HighMapBuffer[shift]!=0)
                          {
                             lasthigh=High[shift];
                             lasthighpos=shift;
                             whatlookfor=-1;
                             ZigZagBuffer[shift]=lasthigh;
                             res=1;
                          }
                          if(LowMapBuffer[shift]!=0)
                          {
                             lastlow=Low[shift];
                             lastlowpos=shift;
                             whatlookfor=1;
                             ZigZagBuffer[shift]=lastlow;
                             res=1;
                          }
                       }
                       break;
                case 1:
                       if((LowMapBuffer[shift]!=0.0)&&(LowMapBuffer[shift]<lastlow)&&(HighMapBuffer[shift]==0.0))
                       {
                          ZigZagBuffer[lastlowpos]=0.0;
                          lastlowpos=shift;
                          lastlow=LowMapBuffer[shift];
                          ZigZagBuffer[shift]=lastlow;
                          res=1;
                       }
                       if((HighMapBuffer[shift]!=0.0)&&(LowMapBuffer[shift]==0.0))
                       {
                          lasthigh=HighMapBuffer[shift];
                          lasthighpos=shift;
                          ZigZagBuffer[shift]=lasthigh;
                          whatlookfor=-1;
                          res=1;
                       }
                       break;
                case -1:
                       if((HighMapBuffer[shift]!=0.0)&&(HighMapBuffer[shift]>lasthigh)&&(LowMapBuffer[shift]==0.0))
                       {
                          ZigZagBuffer[lasthighpos]=0.0;
                          lasthighpos=shift;
                          lasthigh=HighMapBuffer[shift];
                          ZigZagBuffer[shift]=lasthigh;
                          res=1;
                       }
                       if((LowMapBuffer[shift]!=0.0)&&(HighMapBuffer[shift]==0.0))
                       {
                          lastlow=LowMapBuffer[shift];
                          lastlowpos=shift;
                          ZigZagBuffer[shift]=lastlow;
                          whatlookfor=1;
                          res=1;
                       }
                       break;
                 default: return(0);
         }
         /*for(i=1;i<=ZigZagBuffer_num-1;i++)
         {
             ObjectCreate(0,zig+i,OBJ_TREND,0,0,0,0,0);
             ObjectSetInteger(0,zig+i,OBJPROP_COLOR,clrGold);
             ObjectMove(0,zig+i,0,Time[ZigZagBuffer_pos[i]],ZigZagBuffer[ZigZagBuffer_pos[i]]);
             ObjectMove(0,zig+i,1,Time[ZigZagBuffer_pos[i+1]],ZigZagBuffer[ZigZagBuffer_pos[i+1]]);
         }*/
     }
     ZigZagBuffer_num=0;
     int j = barsnum-start;
     j = (j>0)?j:0;
         for(i=barsnum-1;i>=j;i--)
         {
             if(ZigZagBuffer[i]!=0.0)
             {
                ZigZagBuffer_num++;
                ZigZagBuffer_pos[ZigZagBuffer_num]=i;
             }
         }
     return 0;
}


int FRA(int time_frame,double &HighBuffer[],double &LowBuffer[],double &High[],double &Low[],int &High_pos[],int &Low_pos[])
{
    int FRA_Handle=0;
    int barsnum=0;
    bool bFractalsUpper,bFractalsLower;
    int dir,PrevLowPos,PrevHighPos;
    int dir_=0,PrevLowPos_=0,PrevHighPos_=0;
    int limit,Fractals;
    switch(time_frame)
    {
           case 6:
                  FRA_Handle=iFractals(NULL,PERIOD_M5);
                  barsnum=Bars(_Symbol,PERIOD_M5);
                  break;
           case 5:
                  FRA_Handle=iFractals(NULL,PERIOD_M15);
                  barsnum=Bars(_Symbol,PERIOD_M15);
                  break;
    }
    limit=barsnum-2;
    PrevLowPos_=barsnum;
    PrevHighPos_=barsnum;
    dir_=0;
    CopyBuffer(FRA_Handle,0,0,barsnum,UpFractal);
    CopyBuffer(FRA_Handle,1,0,barsnum,DnFractal);
    dir=dir_;
    PrevLowPos=PrevLowPos_;
    PrevHighPos=PrevHighPos_;
    int bar;
    for(bar=limit; bar>=0 && !IsStopped(); bar--)
    {
        if(bar==4)
        {
           dir_=dir;
           PrevLowPos_=PrevLowPos;
           PrevHighPos_=PrevHighPos;
        }
        if(UpFractal[bar]!=EMPTY_VALUE&&UpFractal[bar]) bFractalsUpper=true; else bFractalsUpper=false;
        if(DnFractal[bar]!=EMPTY_VALUE&&DnFractal[bar]) bFractalsLower=true; else bFractalsLower=false;
        Fractals=bFractalsUpper*2+bFractalsLower;
        HighBuffer[bar]=0;
        LowBuffer[bar]=0;
        switch(Fractals)
        {
               case 3:
                      if(!dir)
                      {
                         HighBuffer[bar]=High[bar];
                         LowBuffer[bar]=Low[bar];
                         PrevHighPos=bar;
                         PrevLowPos=bar;
                      }
                      if(dir==1)
                      {
                         LowBuffer[bar]=Low[bar];
                         PrevLowPos=bar;
                         if(High[bar]>High[PrevHighPos])
                         {
                            HighBuffer[bar]=High[bar];
                            HighBuffer[PrevHighPos]=0;
                            PrevHighPos=bar;
                         }
                      }
                      if(dir==-1)
                      {
                         HighBuffer[bar]=High[bar];
                         PrevHighPos=bar;
                         if(Low[bar]<Low[PrevLowPos])
                         {
                            LowBuffer[bar]=Low[bar];
                            LowBuffer[PrevLowPos]=0;
                            PrevLowPos=bar;
                         }
                      }
                      dir*=-1;
                      break;
               case 2:
                      if(dir==1)
                      {
                         if(High[bar]>High[PrevHighPos])
                         {
                            HighBuffer[PrevHighPos]=0;
                            HighBuffer[bar]=High[bar];
                            PrevHighPos=bar;
                         }
                      }
                      else
                      {
                          HighBuffer[bar]=High[bar];
                          PrevHighPos=bar;
                          dir=1;
                      }
                      break;
               case 1:
                      if(dir==-1)
                      {
                         if(Low[bar]<Low[PrevLowPos])
                         {
                            LowBuffer[PrevLowPos]=0;
                            LowBuffer[bar]=Low[bar];
                            PrevLowPos=bar;
                         }
                      }
                      else
                      {
                          LowBuffer[bar]=Low[bar];
                          PrevLowPos=bar;
                          dir=-1;
                      }
                      break;
        }
    }
    int High_num=0,Low_num=0;
    for(bar=barsnum-1;bar>=barsnum-100;bar--)
    {
        if(HighBuffer[bar]!=0)
        {
           High_num++;
           High_pos[High_num]=bar;
        }
        if(LowBuffer[bar]!=0)
        {
           Low_num++;
           Low_pos[Low_num]=bar;
        }
    }
    return 0;
}
int big_TL=100,middle_TL=100;//找通道+画通道
void findtrend()
{
     int i,j;
     big_TL=100;
     middle_TL=100;
     if(ZigZagBuffer_pos_H4[2] <=0) return;
     //以下是1小时线Z字线向下
     if(ZigZagBuffer_H4[ZigZagBuffer_pos_H4[1]]<ZigZagBuffer_H4[ZigZagBuffer_pos_H4[2]])
     {
        for(i=tlines_D-1;i>=0;i--)//找大通道(第一种方法)
        {
            //if(LineShow_U[i][3]==0)continue;
            double temp=ZigZagBuffer_H4[ZigZagBuffer_pos_H4[2]]-ZigZagBuffer_H4[ZigZagBuffer_pos_H4[1]];
            if((High_M1[LineShow_D[i][1]]>ZigZagBuffer_H4[ZigZagBuffer_pos_H4[2]]-temp/6)&&(Time_M1[LineShow_D[i][1]]>Time_H4[ZigZagBuffer_pos_H4[2]-1]))
            {
               for(j=1;j<=2;j++)//判断更接近的大通道
               {
                   if(i-j<0)break;
                   if((High_M1[LineShow_D[i-j][1]]>ZigZagBuffer_H4[ZigZagBuffer_pos_H4[2]]-temp/6)&&(Time_M1[LineShow_D[i-j][1]]>Time_H4[ZigZagBuffer_pos_H4[2]-1]))
                   {
                      double s,s2;
                      s=ObjectGetValueByTime(0,NameTL_D+(i+1),Time_M1[barsnum_M1-1],0);
                      s2=ObjectGetValueByTime(0,NameTL_D+(i-j+1),Time_M1[barsnum_M1-1],0);
                      if(s>s2)
                      {
                         big_TL=-1-i+j;
                         break;
                      }
                   }
               }
               if(big_TL==-1-i+j)break;
               else
               {
                   big_TL=-1-i;
                   break;
               }
            }
        }
        if(big_TL>=100)//找大通道（第二种方法）
        {
           for(i=0;i<tlines_D;i++)
           {
               if(LineShow_D[i][3]==0)continue;
               if(Time_M1[LineShow_D[i][1]]<Time_H4[ZigZagBuffer_pos_H4[2]-1])
               {
                  big_TL=-1-i;
                  break;
               }
           }
        }
        if(big_TL>0)//找大通道（第三种方法）
        {
           if(tlines_D>0)big_TL=(-1)*tlines_D;
        }
        //大通道找完
        if(big_TL<0)
        {
           middle_TL=100;
           int temp_big=(-1)*big_TL-1;
           for(i=temp_big-1;i>=0;i--)//向下的中通道
           {
               if(LineShow_D[i][3]==0)continue;
               if(LineShow_D[i][1]<barsnum_M1-30)
               {
                  middle_TL=-1-i;
                  break;
               }
           }
           for(i=0;i<tlines_U;i++)//向上的中通道
           {
               if(LineShow_U[i][3]==0)continue;
               if(middle_TL<100)
               {
                  int temp_middle=(-1)*middle_TL-1;
                  if((LineShow_U[i][1]<LineShow_D[temp_middle][1])&&(LineShow_U[i][1]>LineShow_D[temp_big][1]))
                  {
                     middle_TL=i+1;
                     break;
                  }
               }
               else 
               {
                   if((LineShow_U[i][1]<barsnum_M1-30)&&(LineShow_U[i][1]>LineShow_D[temp_big][1]))
                   {
                      middle_TL=i+1;
                      break;
                   }
               }
           }
           //画通道
           if(tlines_D>1)ObjectSetInteger(0,NameTL_D+2,OBJPROP_WIDTH,2);
           if(tlines_D>2)ObjectSetInteger(0,NameTL_D+3,OBJPROP_WIDTH,3);
           ObjectSetInteger(0,NameTL_D+((-1)*big_TL),OBJPROP_WIDTH,5);
           j=(-1)*big_TL-1;
           if(tlines_U>1)
           {
              if(LineShow_U[1][1]>LineShow_D[j][1])
              {
                 ObjectSetInteger(0,NameTL_U+2,OBJPROP_WIDTH,2);
              }
           }
           if(tlines_U>2)
           {
              if(LineShow_U[2][1]>LineShow_D[j][1])
              {
                 ObjectSetInteger(0,NameTL_U+3,OBJPROP_WIDTH,3);
              }
           }
           for(i=tlines_U-1;i>=0;i--)
           {
               if(LineShow_U[i][1]>LineShow_D[j][1])break;
           }
           if(i>=0)
           {
              if(LineShow_U[i][1]>LineShow_D[j][1])
              {
                 ObjectSetInteger(0,NameTL_U+(i+1),OBJPROP_WIDTH,4);
              }
           }
           if(middle_TL<100)
           {
              if(middle_TL>0)
              {
                 ObjectSetInteger(0,NameTL_U+(middle_TL),OBJPROP_WIDTH,2);
                 ObjectSetInteger(0,NameTL_U+(middle_TL),OBJPROP_COLOR,clrLightYellow);
              }
              else
              {
                  ObjectSetInteger(0,NameTL_D+((-1)*middle_TL),OBJPROP_WIDTH,2);
                  ObjectSetInteger(0,NameTL_D+((-1)*middle_TL),OBJPROP_COLOR,clrLightYellow);
              }
           }
        }
        else return;
     }
     //以下是Z字线向上
     else
     {
         big_TL=100;
         for(i=tlines_U-1;i>=0;i--)//找大通道(第一种方法)
         {
             double temp=ZigZagBuffer_H4[ZigZagBuffer_pos_H4[1]]-ZigZagBuffer_H4[ZigZagBuffer_pos_H4[2]];
             if((Low_M1[LineShow_U[i][1]]<ZigZagBuffer_H4[ZigZagBuffer_pos_H4[2]]+temp/6)&&(Time_M1[LineShow_U[i][1]]>Time_H4[ZigZagBuffer_pos_H4[2]-1]))
             {
                for(j=1;j<=2;j++)//判断更接近的大通道
                {
                   if(i-j<0)break;
                   if((Low_M1[LineShow_U[i-j][1]]<ZigZagBuffer_H4[ZigZagBuffer_pos_H4[2]]+temp/6)&&(Time_M1[LineShow_U[i-j][1]]>Time_H4[ZigZagBuffer_pos_H4[2]-1]))
                   {
                      double s,s2;
                      s=ObjectGetValueByTime(0,NameTL_U+(i+1),Time_M1[barsnum_M1-1],0);
                      s2=ObjectGetValueByTime(0,NameTL_U+(i-j+1),Time_M1[barsnum_M1-1],0);
                      if(s<s2)
                      {
                         big_TL=i+1-j;
                         break;
                      }
                   }
                }
                if(big_TL==i+1-j)break;
                else
                {
                   big_TL=i+1;
                   break;
                }
             }
         }
         if(big_TL>=100)//找大通道(第二种方法)
         {
            for(i=0;i<tlines_U;i++)
            {
                if(LineShow_U[i][3]==0)continue;
                
                if(Time_M1[LineShow_U[i][1]]<Time_H4[ZigZagBuffer_pos_H4[2]-1])
                {
                   big_TL=i+1;
                   break;
                }
            }
         }
         if(big_TL>=100)//找大通道(第三种方法)
         {
            if(tlines_U>0)big_TL=tlines_U;
         }
         if(big_TL<100)
         {
            middle_TL=100;
            int temp_big=big_TL-1;
            for(i=temp_big-1;i>=0;i--)//找向上的中通道
            {
                //if(LineShow_U[i][3]==0)continue;
                if(LineShow_U[i][1]<barsnum_M1-30)
                {
                   middle_TL=i+1;
                   break;
                }
            }
            for(i=0;i<tlines_D;i++)//找向下的中通道
            {
                //if(LineShow_D[i][3]==0)continue;
                if(middle_TL<100)
                {
                   int temp_middle=middle_TL-1;
                   if((LineShow_D[i][1]<LineShow_U[temp_middle][1])&&(LineShow_D[i][1]>LineShow_U[temp_big][1]))
                   {
                      middle_TL=-1-i;
                      break;
                   }
                }
                else 
                {
                    if((LineShow_D[i][1]<barsnum_M1-30)&&(LineShow_D[i][1]>LineShow_U[temp_big][1]))
                    {
                       middle_TL=-1-i;
                       break;
                    }
                }
            }
            //画通道
            if(tlines_U>1)ObjectSetInteger(0,NameTL_U+2,OBJPROP_WIDTH,2);
            if(tlines_U>2)ObjectSetInteger(0,NameTL_U+3,OBJPROP_WIDTH,3);
            ObjectSetInteger(0,NameTL_U+big_TL,OBJPROP_WIDTH,5);
            j=big_TL-1;
            if(tlines_D>1)
            {
               if(LineShow_D[1][1]>LineShow_U[j][1])
               {
                  ObjectSetInteger(0,NameTL_D+2,OBJPROP_WIDTH,2);
               }
            }
            if(tlines_D>2)
            {
               if(LineShow_D[2][1]>LineShow_U[j][1])
               {
                  ObjectSetInteger(0,NameTL_D+3,OBJPROP_WIDTH,3);
               }
            }
            for(i=tlines_D-1;i>=0;i--)
            {
                if(LineShow_D[i][1]>LineShow_U[j][1])break;
            }
            if(i>=0)
            {
               if(LineShow_D[i][1]>LineShow_U[j][1])
               {
                  ObjectSetInteger(0,NameTL_D+(i+1),OBJPROP_WIDTH,4);
               }
            }
            if(middle_TL<100)
            {
               if(middle_TL>0)
               {
                  ObjectSetInteger(0,NameTL_U+(middle_TL),OBJPROP_WIDTH,2);
                  ObjectSetInteger(0,NameTL_U+(middle_TL),OBJPROP_COLOR,clrLightYellow);
               }
               else
               {
                   ObjectSetInteger(0,NameTL_D+((-1)*middle_TL),OBJPROP_WIDTH,2);
                   ObjectSetInteger(0,NameTL_D+((-1)*middle_TL),OBJPROP_COLOR,clrLightYellow);
               }
            }
         }
     }
}

void trade()//开单总控制
{
     if(ObjectGetString(0,"before_S",OBJPROP_TEXT,0)=="0")//没有找到S点
     {
        if(big_TL>0)
        {
           tradeB0();
           if(PositionSelect(_Symbol)==0)
           {
              if((middle_TL<0)&&(ObjectGetString(0,"before_S",OBJPROP_TEXT,0)=="0"))tradeA1();//中通道向下，A1型
           }
           if(PositionSelect(_Symbol)==0)
           {
              if(ObjectGetString(0,"before_S",OBJPROP_TEXT,0)=="0")tradeA2();
           }
        }
        else
        {
           if(big_TL!=0)
           {
              tradeB0();
              if(PositionSelect(_Symbol)==0)tradeB1();//大通道向上，B1型
              if(PositionSelect(_Symbol)==0)tradeB3();
              if(PositionSelect(_Symbol)==0)
              {
                 if((middle_TL<0)&&(ObjectGetString(0,"before_S",OBJPROP_TEXT,0)=="0"))tradeB2();//中通道向下，B2型
              }
           }
        }
        return;
     }
     if(ObjectGetString(0,"before_S",OBJPROP_TEXT,0)=="A")
     {
        if(big_TL<0)
        {
           ObjectsDeleteAll(0,0,OBJ_ARROW_THUMB_UP);
           ObjectsDeleteAll(0,0,OBJ_LABEL);
           return;
        }
        tradeB0();
        if(PositionSelect(_Symbol)==0)
        {
           if(ObjectGetString(0,"before_S1",OBJPROP_TEXT,0)=="1")
           {
              tradeA1();
           }
        }
        if(PositionSelect(_Symbol)==0)
        {
           if(ObjectGetString(0,"before_S1",OBJPROP_TEXT,0)=="2")
           {
              tradeA2();
           }
        }
        return;
     }
     if(ObjectGetString(0,"before_S",OBJPROP_TEXT,0)=="B")
     {
        if(big_TL>0)
        {
           ObjectsDeleteAll(0,0,OBJ_ARROW_THUMB_UP);
           ObjectsDeleteAll(0,0,OBJ_LABEL);
           return;
        }
        tradeB0();
        if(PositionSelect(_Symbol)==0)
        {
           if(ObjectGetString(0,"before_S1",OBJPROP_TEXT,0)=="1")
           {
              tradeB1();
           }
        }
        if(PositionSelect(_Symbol)==0)
        {
           if(ObjectGetString(0,"before_S1",OBJPROP_TEXT,0)=="2")
           {
              tradeB2();
           }
        }
        return;
     }
}

void createtag()
{
     //1点的值 double
     if(ObjectFind(0,"point1")<0)
     {
        ObjectCreate(0,"point1",OBJ_LABEL,0,0,0);
        ObjectSetString(0,"point1",OBJPROP_TEXT,"0");
     }
     if(ObjectFind(0,"point1_pos")<0)
     {
        ObjectCreate(0,"point1_pos",OBJ_LABEL,0,0,0);
        ObjectSetString(0,"point1_pos",OBJPROP_TEXT,"0");
     }
     //2点的值 double
     if(ObjectFind(0,"point2")<0)
     {
        ObjectCreate(0,"point2",OBJ_LABEL,0,0,0);
        ObjectSetString(0,"point2",OBJPROP_TEXT,"0");
     }
     if(ObjectFind(0,"point2_pos")<0)
     {
        ObjectCreate(0,"point2_pos",OBJ_LABEL,0,0,0);
        ObjectSetString(0,"point2_pos",OBJPROP_TEXT,"0");
     }
     //3点的值 double
     if(ObjectFind(0,"point3")<0)
     {
        ObjectCreate(0,"point3",OBJ_LABEL,0,0,0);
        ObjectSetString(0,"point3",OBJPROP_TEXT,"0");
     }
     if(ObjectFind(0,"point3_pos")<0)
     {
        ObjectCreate(0,"point3_pos",OBJ_LABEL,0,0,0);
        ObjectSetString(0,"point3_pos",OBJPROP_TEXT,"0");
     }
     //4点的值 double
     if(ObjectFind(0,"point4")<0)
     {
        ObjectCreate(0,"point4",OBJ_LABEL,0,0,0);
        ObjectSetString(0,"point4",OBJPROP_TEXT,"0");
     }
     //S点的值 double
     if(ObjectFind(0,"pointS")<0)
     {
        ObjectCreate(0,"pointS",OBJ_LABEL,0,0,0);
        ObjectSetString(0,"pointS",OBJPROP_TEXT,"0");
     }
     //是否破S点 A or B
     if(ObjectFind(0,"before_S")<0)
     {
        ObjectCreate(0,"before_S",OBJ_LABEL,0,0,0);
        ObjectSetString(0,"before_S",OBJPROP_TEXT,"0");
     }
     //是否破S点 1 or 2
     if(ObjectFind(0,"before_S1")<0)
     {
        ObjectCreate(0,"before_S1",OBJ_LABEL,0,0,0);
        ObjectSetString(0,"before_S1",OBJPROP_TEXT,"0");
     }
     //破S点的时间 datetime
     if(ObjectFind(0,"time_po")<0)
     {
        ObjectCreate(0,"time_po",OBJ_LABEL,0,0,0);
        ObjectSetString(0,"time_po",OBJPROP_TEXT,"0");
     }
     //时间级别 12345
     if(ObjectFind(0,"trade_period")<0)
     {
        ObjectCreate(0,"trade_period",OBJ_LABEL,0,0,0);
        ObjectSetString(0,"trade_period",OBJPROP_TEXT,"0");
     }
     //开单时间 datetime
     if(ObjectFind(0,"deal_time")<0)
     {
        ObjectCreate(0,"deal_time",OBJ_LABEL,0,0,0);
        ObjectSetString(0,"deal_time",OBJPROP_TEXT,"0");
     }
     //倒着的
     if(ObjectFind(0,"escape")<0)
     {
        ObjectCreate(0,"escape",OBJ_LABEL,0,0,0);
        ObjectSetString(0,"escape",OBJPROP_TEXT,"0");
     }
     if(ObjectFind(0,"escapeS")<0)
     {
        ObjectCreate(0,"escapeS",OBJ_LABEL,0,0,0);
        ObjectSetString(0,"escapeS",OBJPROP_TEXT,"0");
     }
     if(ObjectFind(0,"escape1")<0)
     {
        ObjectCreate(0,"escape1",OBJ_LABEL,0,0,0);
        ObjectSetString(0,"escape1",OBJPROP_TEXT,"0");
     }
     if(ObjectFind(0,"escape2")<0)
     {
        ObjectCreate(0,"escape2",OBJ_LABEL,0,0,0);
        ObjectSetString(0,"escape2",OBJPROP_TEXT,"0");
     }
     if(ObjectFind(0,"escape3")<0)
     {
        ObjectCreate(0,"escape3",OBJ_LABEL,0,0,0);
        ObjectSetString(0,"escape3",OBJPROP_TEXT,"0");
     }
     if(ObjectFind(0,"estime_po")<0)
     {
        ObjectCreate(0,"estime_po",OBJ_LABEL,0,0,0);
        ObjectSetString(0,"estime_po",OBJPROP_TEXT,"0");
     }
     
     if(ObjectFind(0,"resell")<0)
     {
        ObjectCreate(0,"resell",OBJ_LABEL,0,0,0);
        ObjectSetString(0,"resell",OBJPROP_TEXT,"0");
     }
     //打破1点的时间 datetime
     if(ObjectFind(0,"point1_po")<0)
     {
        ObjectCreate(0,"point1_po",OBJ_LABEL,0,0,0);
        ObjectSetString(0,"point1_po",OBJPROP_TEXT,"0");
     }
     //接单的2点
     if(ObjectFind(0,"point_ag_time")<0)
     {
        ObjectCreate(0,"point_ag_time",OBJ_LABEL,0,0,0);
        ObjectSetString(0,"point_ag_time",OBJPROP_TEXT,"0");
     }
     //记录多单B1开的信息
     if(ObjectFind(0,"B1buy")<0)
     {
        ObjectCreate(0,"B1buy",OBJ_LABEL,0,0,0);
        ObjectSetString(0,"B1buy",OBJPROP_TEXT,"0");
     }
     //
     if(ObjectFind(0,"B1buyvol")<0)
     {
        ObjectCreate(0,"B1buyvol",OBJ_LABEL,0,0,0);
        ObjectSetString(0,"B1buyvol",OBJPROP_TEXT,"0");
     }
     //
     if(ObjectFind(0,"B1buysl")<0)
     {
        ObjectCreate(0,"B1buysl",OBJ_LABEL,0,0,0);
        ObjectSetString(0,"B1buysl",OBJPROP_TEXT,"0");
     }
     //
     if(ObjectFind(0,"B1buypoint")<0)
     {
        ObjectCreate(0,"B1buypoint",OBJ_LABEL,0,0,0);
        ObjectSetString(0,"B1buypoint",OBJPROP_TEXT,"0");
     }
     //B1破S时大通道的宽度
     if(ObjectFind(0,"B1Skuan")<0)
     {
        ObjectCreate(0,"B1Skuan",OBJ_LABEL,0,0,0);
        ObjectSetString(0,"B1Skuan",OBJPROP_TEXT,"0");
     }
     //2次123进场的破S
     if(ObjectFind(0,"beforeS_2to3")<0)
     {
        ObjectCreate(0,"beforeS_2to3",OBJ_LABEL,0,0,0);
        ObjectSetString(0,"beforeS_2to3",OBJPROP_TEXT,"0");
     }
     //2次123进场的1点
     if(ObjectFind(0,"point1_2to3")<0)
     {
        ObjectCreate(0,"point1_2to3",OBJ_LABEL,0,0,0);
        ObjectSetString(0,"point1_2to3",OBJPROP_TEXT,"0");
     }
     //2次123进场的2点
     if(ObjectFind(0,"point2_2to3")<0)
     {
        ObjectCreate(0,"point2_2to3",OBJ_LABEL,0,0,0);
        ObjectSetString(0,"point2_2to3",OBJPROP_TEXT,"0");
     }
     //2次123出场的破S
     if(ObjectFind(0,"escapeS_2to3")<0)
     {
        ObjectCreate(0,"escapeS_2to3",OBJ_LABEL,0,0,0);
        ObjectSetString(0,"escapeS_2to3",OBJPROP_TEXT,"0");
     }
     //2次123出场的1点
     if(ObjectFind(0,"escape1_2to3")<0)
     {
        ObjectCreate(0,"escape1_2to3",OBJ_LABEL,0,0,0);
        ObjectSetString(0,"escape1_2to3",OBJPROP_TEXT,"0");
     }
     //2次123出场的2点
     if(ObjectFind(0,"escape2_2to3")<0)
     {
        ObjectCreate(0,"escape2_2to3",OBJ_LABEL,0,0,0);
        ObjectSetString(0,"escape2_2to3",OBJPROP_TEXT,"0");
     }
     //出场开关
     if(ObjectFind(0,"escape_mode")<0)
     {
        ObjectCreate(0,"escape_mode",OBJ_LABEL,0,0,0);
        ObjectSetString(0,"escape_mode",OBJPROP_TEXT,"0");
     }
     //是否接单，接单时间
     if(ObjectFind(0,"escape_ag")<0)
     {
        ObjectCreate(0,"escape_ag",OBJ_LABEL,0,0,0);
        ObjectSetString(0,"escape_ag",OBJPROP_TEXT,"0");
     }
     //接单价格
     if(ObjectFind(0,"price_ag")<0)
     {
        ObjectCreate(0,"price_ag",OBJ_LABEL,0,0,0);
        ObjectSetString(0,"price_ag",OBJPROP_TEXT,"0");
     }
     //进场的价格
     if(ObjectFind(0,"deal_price")<0)
     {
        ObjectCreate(0,"deal_price",OBJ_LABEL,0,0,0);
        ObjectSetString(0,"deal_price",OBJPROP_TEXT,"0");
     }
     //出场的第二个S点
     if(ObjectFind(0,"beforeS_2")<0)
     {
        ObjectCreate(0,"beforeS_2",OBJ_LABEL,0,0,0);
        ObjectSetString(0,"beforeS_2",OBJPROP_TEXT,"0");
     }
     //出场的第二个1点
     if(ObjectFind(0,"escape1_2")<0)
     {
        ObjectCreate(0,"escape1_2",OBJ_LABEL,0,0,0);
        ObjectSetString(0,"escape1_2",OBJPROP_TEXT,"0");
     }
     //出场的第二个2点
     if(ObjectFind(0,"escape2_2")<0)
     {
        ObjectCreate(0,"escape2_2",OBJ_LABEL,0,0,0);
        ObjectSetString(0,"escape2_2",OBJPROP_TEXT,"0");
     }
}

void findperiod1()
{
     int point1_pos=iLowest(Low_M1,1000,barsnum_M1-1);
     double point1=Low_M1[point1_pos];
     int i;
     string point1_,time_po_;
     for(i=2;i<=4;i++)
     {
         if(i==2)
         {
            ObjectSetString(0,"trade_period",OBJPROP_TEXT,"2");
            if(ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]]>ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]])//如果现在Z字线是高点
            {
               if(ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]]==point1)
               {
                  point1_=DoubleToString(ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]],8);
                  time_po_=TimeToString(Time_M1[barsnum_M1-1]);
                  ObjectSetString(0,"point1",OBJPROP_TEXT,point1_);
                  ObjectCreate(0,"point1t",OBJ_ARROW_THUMB_UP,0,Time_M5[ZigZagBuffer_pos_M5[2]],ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]]);
                  ObjectSetString(0,"time_po",OBJPROP_TEXT,time_po_);
                  break;
               }
            }
            else
            {
                if(ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]]==point1)
                {
                   point1_=DoubleToString(ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]],8);
                   time_po_=TimeToString(Time_M1[barsnum_M1-1]);
                   ObjectSetString(0,"point1",OBJPROP_TEXT,point1_);
                   ObjectCreate(0,"point1t",OBJ_ARROW_THUMB_UP,0,Time_M5[ZigZagBuffer_pos_M5[1]],ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]]);
                   ObjectSetString(0,"time_po",OBJPROP_TEXT,time_po_);
                   break;
                }
            }
         }
         if(i==3)
         {
            ObjectSetString(0,"trade_period",OBJPROP_TEXT,"3");
            if(ZigZagBuffer_M15[ZigZagBuffer_pos_M15[1]]>ZigZagBuffer_M15[ZigZagBuffer_pos_M15[2]])//如果现在Z字线是低点
            {
               if(ZigZagBuffer_M15[ZigZagBuffer_pos_M15[2]]==point1)
               {
                  point1_=DoubleToString(ZigZagBuffer_M15[ZigZagBuffer_pos_M15[2]],8);
                  time_po_=TimeToString(Time_M1[barsnum_M1-1]);
                  ObjectSetString(0,"point1",OBJPROP_TEXT,point1_);
                  ObjectCreate(0,"point1t",OBJ_ARROW_THUMB_UP,0,Time_M15[ZigZagBuffer_pos_M15[2]],ZigZagBuffer_M15[ZigZagBuffer_pos_M15[2]]);
                  ObjectSetString(0,"time_po",OBJPROP_TEXT,time_po_);
                  break;
               }
            }
            else
            {
                if(ZigZagBuffer_M15[ZigZagBuffer_pos_M15[1]]==point1)
                {
                   point1_=DoubleToString(ZigZagBuffer_M15[ZigZagBuffer_pos_M15[1]],8);
                   time_po_=TimeToString(Time_M1[barsnum_M1-1]);
                   ObjectSetString(0,"point1",OBJPROP_TEXT,point1_);
                   ObjectCreate(0,"point1t",OBJ_ARROW_THUMB_UP,0,Time_M15[ZigZagBuffer_pos_M15[1]],ZigZagBuffer_M15[ZigZagBuffer_pos_M15[1]]);
                   ObjectSetString(0,"time_po",OBJPROP_TEXT,time_po_);
                   break;
                }
            }
         }
         if(i==4)
         {
            ObjectSetString(0,"trade_period",OBJPROP_TEXT,"4");
            if(ZigZagBuffer_M30[ZigZagBuffer_pos_M30[1]]>ZigZagBuffer_M30[ZigZagBuffer_pos_M30[2]])//如果现在Z字线是低点
            {
                  point1_=DoubleToString(ZigZagBuffer_M30[ZigZagBuffer_pos_M30[2]],8);
                  time_po_=TimeToString(Time_M1[barsnum_M1-1]);
                  ObjectSetString(0,"point1",OBJPROP_TEXT,point1_);
                  ObjectCreate(0,"point1t",OBJ_ARROW_THUMB_UP,0,Time_M30[ZigZagBuffer_pos_M30[2]],ZigZagBuffer_M30[ZigZagBuffer_pos_M30[2]]);
                  ObjectSetString(0,"time_po",OBJPROP_TEXT,time_po_);
                  break;
            }
            else
            {
                   point1_=DoubleToString(ZigZagBuffer_M30[ZigZagBuffer_pos_M30[1]],8);
                   time_po_=TimeToString(Time_M1[barsnum_M1-1]);
                   ObjectSetString(0,"point1",OBJPROP_TEXT,point1_);
                   ObjectCreate(0,"point1t",OBJ_ARROW_THUMB_UP,0,Time_M30[ZigZagBuffer_pos_M30[1]],ZigZagBuffer_M30[ZigZagBuffer_pos_M30[1]]);
                   ObjectSetString(0,"time_po",OBJPROP_TEXT,time_po_);
                   break;
            }
         }
     }
     return;
}

void findperiod2()
{
     int i;
     double point1=StringToDouble(ObjectGetString(0,"point1",OBJPROP_TEXT,0));
     if(big_TL>0)
     {
        for(i=barsnum_M1-1;i>=LineShow_U[big_TL-1][1];i--)
        {
            if(Low_M1[i]<=point1)break;
        }
     }
     else
     {
         for(i=barsnum_M1-1;i>=LineShow_D[-1*big_TL-1][1];i--)
         {
             if(Low_M1[i]<=point1)break;
         }
     }
     int point1_pos=iHighest(High_M1,barsnum_M1-i,barsnum_M1-1);
     point1=High_M1[point1_pos];
     string point1_,time_po_;
     for(i=2;i<=3;i++)
     {
         if(i==1)
         {
            ObjectSetString(0,"trade_period",OBJPROP_TEXT,"1");
            if(ZigZagBuffer_M1[ZigZagBuffer_pos_M1[1]]<ZigZagBuffer_M1[ZigZagBuffer_pos_M1[2]])//如果现在Z字线是低点
            {
               if(ZigZagBuffer_M1[ZigZagBuffer_pos_M1[2]]==point1)
               {
                  point1_=DoubleToString(ZigZagBuffer_M1[ZigZagBuffer_pos_M1[2]],8);
                  time_po_=TimeToString(Time_M1[barsnum_M1-1]);
                  ObjectSetString(0,"escape1",OBJPROP_TEXT,point1_);
                  ObjectCreate(0,"escape1t",OBJ_ARROW_THUMB_UP,0,Time_M1[ZigZagBuffer_pos_M1[2]],ZigZagBuffer_M1[ZigZagBuffer_pos_M1[2]]);
                  ObjectSetString(0,"estime_po",OBJPROP_TEXT,time_po_);
                  break;
               }
            }
            else
            {
                if(ZigZagBuffer_M1[ZigZagBuffer_pos_M1[1]]==point1)
                {
                   point1_=DoubleToString(ZigZagBuffer_M1[ZigZagBuffer_pos_M1[1]],8);
                   time_po_=TimeToString(Time_M1[barsnum_M1-1]);
                   ObjectSetString(0,"escape1",OBJPROP_TEXT,point1_);
                   ObjectCreate(0,"escape1t",OBJ_ARROW_THUMB_UP,0,Time_M1[ZigZagBuffer_pos_M1[1]],ZigZagBuffer_M1[ZigZagBuffer_pos_M1[1]]);
                   ObjectSetString(0,"estime_po",OBJPROP_TEXT,time_po_);
                   break;
                }
            }
         }
         if(i==2)
         {
            ObjectSetString(0,"trade_period",OBJPROP_TEXT,"2");
            if(ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]]<ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]])//如果现在Z字线是高点
            {
               if(ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]]==point1)
               {
                  point1_=DoubleToString(ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]],8);
                  time_po_=TimeToString(Time_M1[barsnum_M1-1]);
                  ObjectSetString(0,"escape1",OBJPROP_TEXT,point1_);
                  ObjectCreate(0,"escape1t",OBJ_ARROW_THUMB_UP,0,Time_M5[ZigZagBuffer_pos_M5[2]],ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]]);
                  ObjectSetString(0,"estime_po",OBJPROP_TEXT,time_po_);
                  break;
               }
            }
            else
            {
                if(ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]]==point1)
                {
                   point1_=DoubleToString(ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]],8);
                   time_po_=TimeToString(Time_M1[barsnum_M1-1]);
                   ObjectSetString(0,"escape1",OBJPROP_TEXT,point1_);
                   ObjectCreate(0,"escape1t",OBJ_ARROW_THUMB_UP,0,Time_M5[ZigZagBuffer_pos_M5[1]],ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]]);
                   ObjectSetString(0,"estime_po",OBJPROP_TEXT,time_po_);
                   break;
                }
            }
         }
         else
         {
            ObjectSetString(0,"trade_period",OBJPROP_TEXT,"3");
            if(ZigZagBuffer_M15[ZigZagBuffer_pos_M15[1]]<ZigZagBuffer_M15[ZigZagBuffer_pos_M15[2]])//如果现在Z字线是高点
            {
               point1_=DoubleToString(ZigZagBuffer_M15[ZigZagBuffer_pos_M15[2]],8);
               time_po_=TimeToString(Time_M1[barsnum_M1-1]);
               ObjectSetString(0,"escape1",OBJPROP_TEXT,point1_);
               ObjectCreate(0,"escape1t",OBJ_ARROW_THUMB_UP,0,Time_M15[ZigZagBuffer_pos_M15[2]],ZigZagBuffer_M15[ZigZagBuffer_pos_M15[2]]);
               ObjectSetString(0,"estime_po",OBJPROP_TEXT,time_po_);
               break;
            }
            else
            {
                point1_=DoubleToString(ZigZagBuffer_M15[ZigZagBuffer_pos_M15[1]],8);
                time_po_=TimeToString(Time_M1[barsnum_M1-1]);
                ObjectSetString(0,"escape1",OBJPROP_TEXT,point1_);
                ObjectCreate(0,"escape1t",OBJ_ARROW_THUMB_UP,0,Time_M15[ZigZagBuffer_pos_M15[1]],ZigZagBuffer_M15[ZigZagBuffer_pos_M15[1]]);
                ObjectSetString(0,"estime_po",OBJPROP_TEXT,time_po_);
                break;
            }
         }
     }
     return;
}

double findslA1(int period)
{
     int i;
     double sl=0;
     if(period==1)
     {
        if(ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]]<ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]])//倒数第2个Z字点为高点
        {
           for(i=4;i<=12;i++)
           {
               if(ZigZagBuffer_M5[ZigZagBuffer_pos_M5[i]]>ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]])
               {
                  sl=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[i]];
                  break;
               }
           }
           if(sl==0)sl=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]]+200*d_point;
           sl=sl+200*d_point;
           return sl;
        }
        else
        {
            for(i=3;i<=11;i++)
            {
                if(ZigZagBuffer_M5[ZigZagBuffer_pos_M5[i]]>ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]])
                {
                   sl=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[i]];
                   break;
                }
            }
            if(sl==0)sl=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]]+200*d_point;
            sl=sl+200*d_point;
            return sl;
        }
     }
     if(period==2)
     {
        if(ZigZagBuffer_M15[ZigZagBuffer_pos_M15[1]]<ZigZagBuffer_M15[ZigZagBuffer_pos_M15[2]])//倒数第2个Z字点为高点
        {
           for(i=4;i<=12;i++)
           {
               if(ZigZagBuffer_M15[ZigZagBuffer_pos_M15[i]]>ZigZagBuffer_M15[ZigZagBuffer_pos_M15[2]])
               {
                  sl=ZigZagBuffer_M15[ZigZagBuffer_pos_M15[i]];
                  break;
               }
           }
           if(sl==0)sl=ZigZagBuffer_M15[ZigZagBuffer_pos_M15[2]]+200*d_point;
           sl=sl+200*d_point;
           return sl;
        }
        else
        {
            for(i=3;i<=11;i++)
            {
                if(ZigZagBuffer_M15[ZigZagBuffer_pos_M15[i]]>ZigZagBuffer_M15[ZigZagBuffer_pos_M15[1]])
                {
                   sl=ZigZagBuffer_M15[ZigZagBuffer_pos_M15[i]];
                   break;
                }
            }
            if(sl==0)sl=ZigZagBuffer_M15[ZigZagBuffer_pos_M15[1]]+200*d_point;
            sl=sl+200*d_point;
            return sl;
        }
     }
     if(period==3)
     {
        if(ZigZagBuffer_M30[ZigZagBuffer_pos_M30[1]]<ZigZagBuffer_M30[ZigZagBuffer_pos_M30[2]])//倒数第2个Z字点为高点
        {
           for(i=4;i<=12;i++)
           {
               if(ZigZagBuffer_M30[ZigZagBuffer_pos_M30[i]]>ZigZagBuffer_M30[ZigZagBuffer_pos_M30[2]])
               {
                  sl=ZigZagBuffer_M30[ZigZagBuffer_pos_M30[i]];
                  break;
               }
           }
           if(sl==0)sl=ZigZagBuffer_M30[ZigZagBuffer_pos_M30[2]]+200*d_point;
           sl=sl+200*d_point;
           return sl;
        }
        else
        {
            for(i=3;i<=11;i++)
            {
                if(ZigZagBuffer_M30[ZigZagBuffer_pos_M30[i]]>ZigZagBuffer_M30[ZigZagBuffer_pos_M30[1]])
                {
                   sl=ZigZagBuffer_M30[ZigZagBuffer_pos_M30[i]];
                   break;
                }
            }
            if(sl==0)sl=ZigZagBuffer_M30[ZigZagBuffer_pos_M30[1]]+200*d_point;
            sl=sl+200*d_point;
            return sl;
        }
     }
     if(period==4)
     {
        if(ZigZagBuffer_H1[ZigZagBuffer_pos_H1[1]]<ZigZagBuffer_H1[ZigZagBuffer_pos_H1[2]])//倒数第2个Z字点为高点
        {
           for(i=4;i<=12;i++)
           {
               if(ZigZagBuffer_H1[ZigZagBuffer_pos_H1[i]]>ZigZagBuffer_H1[ZigZagBuffer_pos_H1[2]])
               {
                  sl=ZigZagBuffer_H1[ZigZagBuffer_pos_H1[i]];
                  break;
               }
           }
           if(sl==0)sl=ZigZagBuffer_H1[ZigZagBuffer_pos_H1[2]]+200*d_point;
           sl=sl+200*d_point;
           return sl;
        }
        else
        {
            for(i=3;i<=11;i++)
            {
                if(ZigZagBuffer_H1[ZigZagBuffer_pos_H1[i]]>ZigZagBuffer_H1[ZigZagBuffer_pos_H1[1]])
                {
                   sl=ZigZagBuffer_H1[ZigZagBuffer_pos_H1[i]];
                   break;
                }
            }
            if(sl==0)sl=ZigZagBuffer_H1[ZigZagBuffer_pos_H1[1]]+200*d_point;
            sl=sl+200*d_point;
            return sl;
        }
     }
     return 0;
}

double findslB1()
{
     int point1_pos=iHighest(High_M1,1000,barsnum_M1-1);
     double point1=High_M1[point1_pos];
     double sl=point1+200*d_point;
     return sl;
}

void tradeA1()
{
     if(enable_A1==false)return;
     int i,j;
     double nowp=SymbolInfoDouble(_Symbol,SYMBOL_BID);
     string point1_,time_po_,pointS_;
     int dis;
     double div;
     double breakP1,breakP3,breakP4,breakP11;
     double kuan;
     string kuan_;
     int flag=1;
     double point1_2to3,point2_2to3;
     datetime timeS_2to3;
     string timeS_2to3_,point1_2to3_,point2_2to3_;
     int pos;
     double zig1;
     datetime time1;
     double vol_A1=0.40;
     if(yuanyou==true)vol_A1=4;
     if(ObjectGetString(0,"before_S",OBJPROP_TEXT,0)=="0")
     {
        //以下是设置中通道的打破位置
        i=-1*middle_TL-1;
        dis=LineShow_D[i][0]-LineShow_D[i][1];
        if(dis!=0)
        {
           div=High_M1[LineShow_D[i][0]]-High_M1[LineShow_D[i][1]];
           breakP4=div*(barsnum_M1-4-LineShow_D[i][0])/dis+High_M1[LineShow_D[i][0]];
           breakP3=div*(barsnum_M1-3-LineShow_D[i][0])/dis+High_M1[LineShow_D[i][0]];
           breakP1=div*(barsnum_M1-1-LineShow_D[i][0])/dis+High_M1[LineShow_D[i][0]];
           if(i<tlines_D-1)
           {
              dis=LineShow_D[i+1][0]-LineShow_D[i+1][1];
              if(dis!=0)
              {
                 div=High_M1[LineShow_D[i+1][0]]-High_M1[LineShow_D[i+1][1]];
                 breakP11=div*(barsnum_M1-1-LineShow_D[i+1][0])/dis+High_M1[LineShow_D[i+1][0]];
                 if(breakP11<breakP1+300*d_point)flag=0;
              }
           }
           if(flag==1)
           {
              kuan=div*(LineShow_D[i][2]-LineShow_D[i][0])/dis+High_M1[LineShow_D[i][0]];
              kuan=kuan-Low_M1[LineShow_D[i][2]];
              kuan_=DoubleToString(kuan,8);
              if(nowp>breakP1+300*d_point)
              {
                 ObjectSetString(0,"before_S",OBJPROP_TEXT,"A");//标记“找到S点 A型开单”
                 ObjectSetString(0,"before_S1",OBJPROP_TEXT,"1");//A1型
                 pointS_=DoubleToString(breakP1,8);
                 ObjectSetString(0,"pointS",OBJPROP_TEXT,pointS_);
                 ObjectCreate(0,"pointSt",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                 ObjectSetString(0,"B1Skuan",OBJPROP_TEXT,kuan_);
                 pos=iLowest(Low_M1,barsnum_M1-LineShow_D[-1*middle_TL-1][1],barsnum_M1);
                 if(ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]]<ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]])
                 {
                    zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
                    time1=Time_M5[ZigZagBuffer_pos_M5[1]];
                 }
                 else 
                 {
                     zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
                     time1=Time_M5[ZigZagBuffer_pos_M5[2]];
                 }
                 for(i=tlines_U-1;i>=0;i--)
                 {
                     if((LineShow_U[i][1]<pos+60)&&(LineShow_U[i][1]>pos-60)&&(LineShow_U[i][1]-LineShow_U[i][0]>150))break;
                 }
                 if(i>=0)
                 {
                    if(Low_M1[LineShow_U[i][0]]<zig1)
                    {
                       point1_=DoubleToString(Low_M1[LineShow_U[i][0]],8);
                       ObjectSetString(0,"point1",OBJPROP_TEXT,point1_);
                       ObjectCreate(0,"point1t",OBJ_ARROW_THUMB_UP,0,Time_M1[LineShow_U[i][0]],Low_M1[LineShow_U[i][0]]);
                    }
                    else
                    {
                        point1_=DoubleToString(zig1,8);
                        ObjectSetString(0,"point1",OBJPROP_TEXT,point1_);
                        ObjectCreate(0,"point1t",OBJ_ARROW_THUMB_UP,0,time1,zig1);
                    }
                 }
                 else
                 {
                     point1_=DoubleToString(zig1,8);
                     ObjectSetString(0,"point1",OBJPROP_TEXT,point1_);
                     ObjectCreate(0,"point1t",OBJ_ARROW_THUMB_UP,0,time1,zig1);
                 }
                 time_po_=TimeToString(Time_M1[barsnum_M1-1]);
                 ObjectSetString(0,"time_po",OBJPROP_TEXT,time_po_);
                 Alert("A1S");
                 return;
              }
              if(High_M1[barsnum_M1-3]>breakP3+5*d_point)
              {
                 if((nowp>=High_M1[barsnum_M1-2]+5*d_point)&&(High_M1[barsnum_M1-2]>High_M1[barsnum_M1-3])&&(High_M1[barsnum_M1-4]>=breakP4))
                 {
                    ObjectSetString(0,"before_S",OBJPROP_TEXT,"A");//标记“找到S点 A型开单”
                    ObjectSetString(0,"before_S1",OBJPROP_TEXT,"1");//A1型
                    pointS_=DoubleToString(nowp,8);
                    ObjectSetString(0,"pointS",OBJPROP_TEXT,pointS_);
                    ObjectCreate(0,"pointSt",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                    ObjectSetString(0,"B1Skuan",OBJPROP_TEXT,kuan_);
                    pos=iLowest(Low_M1,barsnum_M1-LineShow_D[-1*middle_TL-1][1],barsnum_M1);
                    if(ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]]<ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]])
                    {
                       zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
                       time1=Time_M5[ZigZagBuffer_pos_M5[1]];
                    }
                    else 
                    {
                        zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
                        time1=Time_M5[ZigZagBuffer_pos_M5[2]];
                    }
                    for(i=tlines_U-1;i>=0;i--)
                    {
                        if((LineShow_U[i][1]<pos+60)&&(LineShow_U[i][1]>pos-60)&&(LineShow_U[i][1]-LineShow_U[i][0]>150))break;
                    }
                    if(i>=0)
                    {
                       if(Low_M1[LineShow_U[i][0]]>zig1)
                       {
                          point1_=DoubleToString(Low_M1[LineShow_U[i][0]],8);
                          ObjectSetString(0,"point1",OBJPROP_TEXT,point1_);
                          ObjectCreate(0,"point1t",OBJ_ARROW_THUMB_UP,0,Time_M1[LineShow_U[i][0]],Low_M1[LineShow_U[i][0]]);
                       }
                       else
                       {
                           point1_=DoubleToString(zig1,8);
                           ObjectSetString(0,"point1",OBJPROP_TEXT,point1_);
                           ObjectCreate(0,"point1t",OBJ_ARROW_THUMB_UP,0,time1,zig1);
                       }
                    }
                    else
                    {
                        point1_=DoubleToString(zig1,8);
                        ObjectSetString(0,"point1",OBJPROP_TEXT,point1_);
                        ObjectCreate(0,"point1t",OBJ_ARROW_THUMB_UP,0,time1,zig1);
                    }
                    time_po_=TimeToString(Time_M1[barsnum_M1-1]);
                    ObjectSetString(0,"time_po",OBJPROP_TEXT,time_po_);
                    Alert("A1S");
                    return;
                 }
              }
           }
        }
     }
     if((ObjectGetString(0,"before_S",OBJPROP_TEXT,0)=="A")&&(ObjectGetString(0,"before_S1",OBJPROP_TEXT,0)=="1")) //A1型
     {
         datetime time_po;
         double point1,point2,pointS,kuan;
         string point2_,point3_,deal_time_;
         point1=StringToDouble(ObjectGetString(0,"point1",OBJPROP_TEXT,0));
         pointS=StringToDouble(ObjectGetString(0,"pointS",OBJPROP_TEXT,0));
         time_po=StringToTime(ObjectGetString(0,"time_po",OBJPROP_TEXT,0));
         kuan=StringToDouble(ObjectGetString(0,"B1Skuan",OBJPROP_TEXT,0));
         if(nowp<point1)
         {
            ObjectsDeleteAll(0,0,OBJ_ARROW_THUMB_UP);
            ObjectsDeleteAll(0,0,OBJ_LABEL);
            return;
         }
         if(ObjectGetString(0,"point2",OBJPROP_TEXT,0)=="0")//没有出现2点
         {
            double zig1,zig2;
            datetime time1,time2;
            zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
            zig2=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
            time1=Time_M5[ZigZagBuffer_pos_M5[1]+2];
            time2=Time_M5[ZigZagBuffer_pos_M5[2]+2];
            int timeS=ObjectGetInteger(0,"pointSt",OBJPROP_TIME,0);
            if((zig1<zig2)&&(time2>=time_po))
            {
               point2_=DoubleToString(zig2,8);
               ObjectSetString(0,"point2",OBJPROP_TEXT,point2_);
               ObjectCreate(0,"point2t",OBJ_ARROW_THUMB_UP,0,time2,zig2);
               return;
            }
         }
         else
         {   
             double zig1,zig2;
             datetime time3;
             point2=StringToDouble(ObjectGetString(0,"point2",OBJPROP_TEXT,0));
             zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
             zig2=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
             time3=Time_M5[ZigZagBuffer_pos_M5[2]+2];
             int flag_2to3=0;
             for(i=0;i<tlines_U;i++)
             {
                 if((Time_M1[LineShow_U[i][1]]>time_po)&&(Low_M1[LineShow_U[i][1]]<point2+(nowp-point2)/3))
                 {
                    flag_2to3=1;
                    break;
                 }
             }
             if(ObjectGetString(0,"beforeS_2to3",OBJPROP_TEXT,0)=="0")
             {
                if((flag_2to3==1)&&(i<tlines_D))
                {
                    dis=LineShow_D[i][0]-LineShow_D[i][1];
                    if(dis!=0)
                    {
                       div=High_M1[LineShow_D[i][0]]-High_M1[LineShow_D[i][1]];
                       breakP1=div*(barsnum_M1-1-LineShow_D[i][0])/dis+High_M1[LineShow_D[i][0]];
                       breakP3=div*(barsnum_M1-3-LineShow_D[i][0])/dis+High_M1[LineShow_D[i][0]];
                       breakP4=div*(barsnum_M1-4-LineShow_D[i][0])/dis+High_M1[LineShow_D[i][0]];
                       if(nowp>breakP1+50*d_point)
                       {
                          timeS_2to3_=TimeToString(Time_M5[barsnum_M5-1]);
                          point1_2to3=Low_M1[iLowest(Low_M1,barsnum_M1-LineShow_D[i][1],barsnum_M1-1)];
                          point1_2to3_=DoubleToString(point1_2to3,8);
                          ObjectSetString(0,"beforeS_2to3",OBJPROP_TEXT,timeS_2to3_);
                          ObjectSetString(0,"point1_2to3",OBJPROP_TEXT,point1_2to3_);
                          ObjectCreate(0,"pointS_2to3t",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                          return;
                       }
                       if(High_M1[barsnum_M1-3]>breakP3+5*d_point)
                       {
                          if((nowp>=High_M1[barsnum_M1-2]+5*d_point)&&(High_M1[barsnum_M1-2]>High_M1[barsnum_M1-3])&&(High_M1[barsnum_M1-4]>=breakP4))
                          {
                             timeS_2to3_=TimeToString(Time_M5[barsnum_M5-1]);
                             point1_2to3=Low_M1[iLowest(Low_M1,barsnum_M1-LineShow_D[i][1],barsnum_M1-1)];
                             point1_2to3_=DoubleToString(point1_2to3,8);
                             ObjectSetString(0,"beforeS_2to3",OBJPROP_TEXT,timeS_2to3_);
                             ObjectSetString(0,"point1_2to3",OBJPROP_TEXT,point1_2to3_);
                             ObjectCreate(0,"pointS_2to3t",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                             return;
                          }
                       }
                    }
                }
             }
             else
             {
                 point1_2to3=StringToDouble(ObjectGetString(0,"point1_2to3",OBJPROP_TEXT,0));
                 if(nowp<point1_2to3)
                 {
                    ObjectDelete(0,"beforeS_2to3");
                    ObjectDelete(0,"point1_2to3");
                    ObjectDelete(0,"pointS_2to3t");
                    ObjectDelete(0,"point2_2to3");
                    ObjectDelete(0,"point2_2to3t");
                    return;
                 }
                 if(ObjectGetString(0,"point2_2to3",OBJPROP_TEXT,0)=="0")
                 {
                    point2_2to3_=DoubleToString(nowp,8);
                    ObjectSetString(0,"point2_2to3",OBJPROP_TEXT,point2_2to3_);
                    ObjectCreate(0,"point2_2to3t",OBJ_ARROW_THUMB_UP,0,Time_M5[barsnum_M5-1],nowp);
                    return;
                 }
                 else
                 {
                     point2_2to3=StringToDouble(ObjectGetString(0,"point2_2to3",OBJPROP_TEXT,0));
                     timeS_2to3=StringToTime(ObjectGetString(0,"beforeS_2to3",OBJPROP_TEXT,0));
                     if(Time_M5[barsnum_M5-2]>timeS_2to3)
                     {
                        if(High_M5[barsnum_M5-2]>point2_2to3)
                        {
                           point2_2to3_=DoubleToString(High_M5[barsnum_M5-2],8);
                           ObjectSetString(0,"point2_2to3",OBJPROP_TEXT,point2_2to3_);
                           ObjectSetDouble(0,"point2_2to3t",OBJPROP_PRICE,High_M5[barsnum_M5-2]);
                           ObjectSetInteger(0,"point2_2to3t",OBJPROP_TIME,Time_M5[barsnum_M5-2]);
                           return;
                        }
                        if((High_M5[barsnum_M5-2]<point2_2to3)&&(nowp>point2_2to3))
                        {
                           deal_time_=TimeToString(Time_M1[barsnum_M1-1]);
                           ObjectSetString(0,"deal_time",OBJPROP_TEXT,deal_time_);
                           point3_=DoubleToString(point1_2to3,8);
                           ObjectSetString(0,"point3",OBJPROP_TEXT,point3_);
                           fbuy(point1-500*d_point,vol_A1);
                           Alert("2次123进场");
                           return;
                        }
                     }
                 }
             }
             if((zig1>zig2)&&(time3>=time_po))
             {
                if(zig2<pointS)
                {
                   if((nowp>pointS+10*d_point)&&(pointS-point1>=150*d_point)&&(point2-pointS>=50*d_point))
                   {
                      //sl=findsl(nowp);
                      string deal_time_=TimeToString(Time_M1[barsnum_M1-1]);
                      ObjectSetString(0,"deal_time",OBJPROP_TEXT,deal_time_);
                      point3_=DoubleToString(zig2,8);
                      ObjectSetString(0,"point3",OBJPROP_TEXT,point3_);
                      ObjectCreate(0,"point3t",OBJ_ARROW_THUMB_UP,0,Time_M5[ZigZagBuffer_pos_M5[2]],zig2);
                      fbuy(point1-500*d_point,vol_A1);
                      Alert("A1,Z字线123进场");
                      return;
                   }
                }
                else
                {
                    if(nowp>point2+10*d_point)
                    {
                       string deal_time_=TimeToString(Time_M1[barsnum_M1-1]);
                       ObjectSetString(0,"deal_time",OBJPROP_TEXT,deal_time_);
                       point3_=DoubleToString(zig2,8);
                       ObjectSetString(0,"point3",OBJPROP_TEXT,point3_);
                       ObjectCreate(0,"point3t",OBJ_ARROW_THUMB_UP,0,Time_M5[ZigZagBuffer_pos_M5[2]],zig2);
                       fbuy(point1-500*d_point,vol_A1);
                       Alert("A1,Z字线123进场");
                       return;
                    }
                }
             }
         }
     }
}

void tradeA2()
{
     if(enable_A2==false)return;
     int i,j;
     double nowp=SymbolInfoDouble(_Symbol,SYMBOL_BID);
     string point1_,time_po_,pointS_;
     int dis;
     double div;
     double breakP1,breakP3,breakP4,breakP11;
     double kuan;
     string kuan_;
     int flag=1;
     int point1_pos;
     double point1;
     datetime timeS_2to3;
     double point1_2to3,point2_2to3;
     string timeS_2to3_,point1_2to3_,point2_2to3_;
     double vol_A2=0.38;
     if(yuanyou==true)vol_A2=3.8;
     if(ObjectGetString(0,"before_S",OBJPROP_TEXT,0)=="0")
     {
        //以下是设置支撑线的打破位置
        i=Hnum_M5;
        dis=LineHP_M5_2[i]-LineHP_M5_1[i];
        if(dis!=0)
        {
           div=High_M5[LineHP_M5_2[i]]-High_M5[LineHP_M5_1[i]];
           breakP1=div*(barsnum_M5-1-LineHP_M5_2[i])/dis+High_M5[LineHP_M5_2[i]];
           if(nowp>breakP1+50*d_point)
           {
              ObjectSetString(0,"before_S",OBJPROP_TEXT,"A");//标记“找到S点 A型开单
              ObjectSetString(0,"before_S1",OBJPROP_TEXT,"2");//A2型
              pointS_=DoubleToString(breakP1,8);
              ObjectSetString(0,"pointS",OBJPROP_TEXT,pointS_);
              ObjectCreate(0,"pointSt",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
              point1_pos=iLowest(Low_M5,barsnum_M5-LineHP_M5_2[i],barsnum_M5-1);
              point1=Low_M5[point1_pos];
              point1_=DoubleToString(point1,8);
              ObjectSetString(0,"point1",OBJPROP_TEXT,point1_);
              ObjectCreate(0,"point1t",OBJ_ARROW_THUMB_UP,0,Time_M5[point1_pos],point1);
              time_po_=TimeToString(Time_M1[barsnum_M1-1]);
              ObjectSetString(0,"time_po",OBJPROP_TEXT,time_po_);
              Alert("A2S");
              return;
           }
        }
     }
     if((ObjectGetString(0,"before_S",OBJPROP_TEXT,0)=="A")&&(ObjectGetString(0,"before_S1",OBJPROP_TEXT,0)=="2")) //A2型
     {
         datetime time_po;
         double point1,point2,pointS;
         string point2_,point3_,deal_time_;
         point1=StringToDouble(ObjectGetString(0,"point1",OBJPROP_TEXT,0));
         pointS=StringToDouble(ObjectGetString(0,"pointS",OBJPROP_TEXT,0));
         time_po=StringToTime(ObjectGetString(0,"time_po",OBJPROP_TEXT,0));
         if(nowp<point1)
         {
            ObjectsDeleteAll(0,0,OBJ_ARROW_THUMB_UP);
            ObjectsDeleteAll(0,0,OBJ_LABEL);
            return;
         }
         if(ObjectGetString(0,"point2",OBJPROP_TEXT,0)=="0")//没有出现2点
         {
            double zig1,zig2;
            datetime time1,time2;
            zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
            zig2=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
            time1=Time_M5[ZigZagBuffer_pos_M5[1]+2];
            time2=Time_M5[ZigZagBuffer_pos_M5[2]+2];
            int timeS=ObjectGetInteger(0,"pointSt",OBJPROP_TIME,0);
            if((zig1<zig2)&&(time2>=time_po))
            {
               point2_=DoubleToString(zig2,8);
               ObjectSetString(0,"point2",OBJPROP_TEXT,point2_);
               ObjectCreate(0,"point2t",OBJ_ARROW_THUMB_UP,0,time2,zig2);
               return;
            }
         }
         else
         {   
             double zig1,zig2;
             datetime time3;
             point2=StringToDouble(ObjectGetString(0,"point2",OBJPROP_TEXT,0));
             zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
             zig2=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
             time3=Time_M5[ZigZagBuffer_pos_M5[2]+2];
             int flag_2to3=0;
             for(i=0;i<tlines_D;i++)
             {
                 if((Time_M1[LineShow_D[i][1]]>time_po)&&(High_M1[LineShow_D[i][1]]>point2-(point2-nowp)/3))
                 {
                    flag_2to3=1; 
                    break;
                 }
             }
             if(ObjectGetString(0,"beforeS_2to3",OBJPROP_TEXT,0)=="0")
             {
                if((flag_2to3==1)&&(i<tlines_D))
                {
                   dis=LineShow_D[i][0]-LineShow_D[i][1];
                   if(dis!=0)
                   {
                      div=High_M1[LineShow_D[i][0]]-High_M1[LineShow_D[i][1]];
                      breakP1=div*(barsnum_M1-1-LineShow_D[i][0])/dis+High_M1[LineShow_D[i][0]];
                      breakP3=div*(barsnum_M1-3-LineShow_D[i][0])/dis+High_M1[LineShow_D[i][0]];
                      breakP4=div*(barsnum_M1-4-LineShow_D[i][0])/dis+High_M1[LineShow_D[i][0]];
                      if(nowp>breakP1+50*d_point)
                      {
                         timeS_2to3_=TimeToString(Time_M5[barsnum_M5-1]);
                         point1_2to3=Low_M1[iLowest(Low_M1,barsnum_M1-LineShow_D[i][1],barsnum_M1-1)];
                         point1_2to3_=DoubleToString(point1_2to3,8);
                         ObjectSetString(0,"beforeS_2to3",OBJPROP_TEXT,timeS_2to3_);
                         ObjectSetString(0,"point1_2to3",OBJPROP_TEXT,point1_2to3_);
                         ObjectCreate(0,"pointS_2to3t",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                         return;
                      }
                      if(High_M1[barsnum_M1-3]>breakP3+5*d_point)
                      {
                         if((nowp>=High_M1[barsnum_M1-2]+5*d_point)&&(High_M1[barsnum_M1-2]>High_M1[barsnum_M1-3])&&(High_M1[barsnum_M1-4]>=breakP4))
                         {
                             timeS_2to3_=TimeToString(Time_M5[barsnum_M5-1]);
                             point1_2to3=Low_M1[iLowest(Low_M1,barsnum_M1-LineShow_D[i][1],barsnum_M1-1)];
                             point1_2to3_=DoubleToString(point1_2to3,8);
                             ObjectSetString(0,"beforeS_2to3",OBJPROP_TEXT,timeS_2to3_);
                             ObjectSetString(0,"point1_2to3",OBJPROP_TEXT,point1_2to3_);
                             ObjectCreate(0,"pointS_2to3t",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                             return;
                         }
                      }
                   }
                }
             }
             else
             {
                 point1_2to3=StringToDouble(ObjectGetString(0,"point1_2to3",OBJPROP_TEXT,0));
                 if(nowp<point1_2to3)
                 {
                    ObjectDelete(0,"beforeS_2to3");
                    ObjectDelete(0,"point1_2to3");
                    ObjectDelete(0,"pointS_2to3t");
                    ObjectDelete(0,"point2_2to3");
                    ObjectDelete(0,"point2_2to3t");
                    return;
                 }
                 if(ObjectGetString(0,"point2_2to3",OBJPROP_TEXT,0)=="0")
                 {
                    point2_2to3_=DoubleToString(nowp,8);
                    ObjectSetString(0,"point2_2to3",OBJPROP_TEXT,point2_2to3_);
                    ObjectCreate(0,"point2_2to3t",OBJ_ARROW_THUMB_UP,0,Time_M5[barsnum_M5-1],nowp);
                    return;
                 }
                 else
                 {
                     point2_2to3=StringToDouble(ObjectGetString(0,"point2_2to3",OBJPROP_TEXT,0));
                     timeS_2to3=StringToTime(ObjectGetString(0,"beforeS_2to3",OBJPROP_TEXT,0));
                     if(Time_M5[barsnum_M5-2]>timeS_2to3)
                     {
                        if(High_M5[barsnum_M5-2]>point2_2to3)
                        {
                           point2_2to3_=DoubleToString(High_M5[barsnum_M5-2],8);
                           ObjectSetString(0,"point2_2to3",OBJPROP_TEXT,point2_2to3_);
                           ObjectSetDouble(0,"point2_2to3t",OBJPROP_PRICE,High_M5[barsnum_M5-2]);
                           ObjectSetInteger(0,"point2_2to3t",OBJPROP_TIME,Time_M5[barsnum_M5-2]);
                           return;
                        }
                        if((High_M5[barsnum_M5-2]<point2_2to3)&&(nowp>point2_2to3))
                        {
                           deal_time_=TimeToString(Time_M1[barsnum_M1-1]);
                           ObjectSetString(0,"deal_time",OBJPROP_TEXT,deal_time_);
                           point3_=DoubleToString(point1_2to3,8);
                           ObjectSetString(0,"point3",OBJPROP_TEXT,point3_);
                           fbuy(point1-500*d_point,vol_A2);
                           Alert("A2,2次123进场");
                           return;
                        }
                     }
                 }
             }
             if((zig1>zig2)&&(time3>=time_po))
             {
                if(zig2<pointS)
                {
                   if((nowp>pointS+10*d_point)&&(pointS-point1>=150*d_point)&&(point2-pointS>=50*d_point))
                   {
                      //sl=findsl(nowp);
                      string deal_time_=TimeToString(Time_M1[barsnum_M1-1]);
                      ObjectSetString(0,"deal_time",OBJPROP_TEXT,deal_time_);
                      point3_=DoubleToString(zig2,8);
                      ObjectSetString(0,"point3",OBJPROP_TEXT,point3_);
                      ObjectCreate(0,"point3t",OBJ_ARROW_THUMB_UP,0,Time_M5[ZigZagBuffer_pos_M5[2]],zig2);
                      fbuy(point1-500*d_point,vol_A2);
                      Alert("A2,Z字线123进场");
                      return;
                   }
                }
                else
                {
                    if(nowp>point2+10*d_point)
                    {
                       string deal_time_=TimeToString(Time_M1[barsnum_M1-1]);
                       ObjectSetString(0,"deal_time",OBJPROP_TEXT,deal_time_);
                       point3_=DoubleToString(zig2,8);
                       ObjectSetString(0,"point3",OBJPROP_TEXT,point3_);
                       ObjectCreate(0,"point3t",OBJ_ARROW_THUMB_UP,0,Time_M5[ZigZagBuffer_pos_M5[2]],zig2);
                       fbuy(point1-500*d_point,vol_A2);
                       Alert("A2,Z字线123进场");
                       return;
                    }
                }
             }
          }
      }
}

void tradeB0()
{
     if(enable_B0==false)return;
     int i;
     double nowp=SymbolInfoDouble(_Symbol,SYMBOL_BID);
     double point1=0,point2=0,point3=0;
     string point1_,point2_,point3_;
     int point1_pos=0,point2_pos=0,point3_pos=0,pointh_pos=0;
     datetime nowtime=SymbolInfoInteger(_Symbol,SYMBOL_TIME);//当前时间
     //Print("barsnum_D1-15 ",barsnum_D1-15);
     //Print("Time_D1[barsnum_D1-15] ",Time_D1[barsnum_D1-15]);
     HistorySelect(Time_D1[barsnum_D1-15],nowtime);
     int order_num=HistoryOrdersTotal();//选择的历史区间内总交易次数
     int ticket=HistoryOrderGetTicket(order_num-1);//这是上一个单的ticket
     datetime order_time=HistoryOrderGetInteger(ticket,ORDER_TIME_DONE);
     double order_vol=HistoryOrderGetDouble(ticket,ORDER_VOLUME_INITIAL);
     int order_type=HistoryOrderGetInteger(ticket,ORDER_TYPE);
     double order_price=HistoryOrderGetDouble(ticket,ORDER_PRICE_OPEN);
     double vol_B0=0.46;
     if(yuanyou==true)vol_B0=4.6;
     if(order_num>0)
     {
        ObjectSetString(0,"point_ag_time",OBJPROP_TEXT,"1");
        for(i=order_num-2;i>=0;i--)
        {
            ticket=HistoryOrderGetTicket(i);
            order_type=HistoryOrderGetInteger(ticket,ORDER_TYPE);
            if(order_type==ORDER_TYPE_BUY)break;
        }
        if(i>=0)order_time=HistoryOrderGetInteger(ticket,ORDER_TIME_DONE);
        for(i=barsnum_M1-1;i>=barsnum_M1-50000;i--)
        {
            if(Time_M1[i]<=order_time)break;
        }
        point2_pos=iHighest(High_M1,barsnum_M1-i,barsnum_M1-5);
        point2=High_M1[point2_pos];
        if(ObjectFind(0,"B0point2t")<0)
        {
           ObjectCreate(0,"B0point2t",OBJ_ARROW_THUMB_DOWN,0,Time_M1[point2_pos],point2);
        }
        else
        {
            if(ObjectGetDouble(0,"B0point2t",OBJPROP_PRICE,0)!=point2)
               ObjectSetDouble(0,"B0point2t",OBJPROP_PRICE,point2);
               ObjectSetInteger(0,"B0point2t",OBJPROP_TIME,Time_M1[point2_pos]);
        }
        if(ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]]<ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]])
        {
           for(i=1;i<=13;i=i+2)
           {
               if(Time_M5[ZigZagBuffer_pos_M5[i]]<Time_M1[point2_pos])
               {
                  point1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[i]];
                  point1_pos=ZigZagBuffer_pos_M5[i];
                  break;
               }
           }
           point1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[i]];
           point1_pos=ZigZagBuffer_pos_M5[i];
        }
        else
        {
            for(i=2;i<=14;i=i+2)
            {
                if(Time_M5[ZigZagBuffer_pos_M5[i]]<Time_M1[point2_pos])
                {
                   point1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[i]];
                   point1_pos=ZigZagBuffer_pos_M5[i];
                   break;
                }
            }
            point1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[i]];
            point1_pos=ZigZagBuffer_pos_M5[i];
        }
        point3_pos=iLowest(Low_M1,barsnum_M1-point2_pos,barsnum_M1-5);
        point3=Low_M1[point3_pos];
     }
     if(ObjectGetString(0,"point_ag_time",OBJPROP_TEXT,0)=="1")
     {
        if((nowp>point2+10*d_point)&&(point2>0))
        {
           ObjectSetString(0,"before_S",OBJPROP_TEXT,"B");
           ObjectSetString(0,"before_S1",OBJPROP_TEXT,"0");
           string deal_time_=TimeToString(Time_M1[barsnum_M1-1]);
           ObjectSetString(0,"deal_time",OBJPROP_TEXT,deal_time_);
           point1_=DoubleToString(point1,8);
           ObjectSetString(0,"point1",OBJPROP_TEXT,point1_);
           ObjectCreate(0,"point1t",OBJ_ARROW_THUMB_UP,0,Time_M5[point1_pos],point1);
           point2_=DoubleToString(point2,8);
           ObjectSetString(0,"point2",OBJPROP_TEXT,point2_);
           ObjectCreate(0,"point2t",OBJ_ARROW_THUMB_UP,0,Time_M1[point2_pos],point2);
           point3_=DoubleToString(point3,8);
           ObjectSetString(0,"point3",OBJPROP_TEXT,point3_);
           ObjectCreate(0,"point3t",OBJ_ARROW_THUMB_UP,0,Time_M1[point3_pos],point3);
           fbuy(point1-350*d_point,vol_B0);
           Alert("接单");
           return;
        }
        ticket=HistoryOrderGetTicket(order_num-1);//这是上一个单的ticket
        order_time=HistoryOrderGetInteger(ticket,ORDER_TIME_DONE);
        if(big_TL>0)
        {
           if(ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]]<ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]])
           {
              if((Time_M5[ZigZagBuffer_pos_M5[3]]>order_time)&&(ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]]<order_price-300*d_point))
              {
                  if(nowp>order_price-50*d_point)
                  {
                     ObjectSetString(0,"before_S",OBJPROP_TEXT,"B");
                     ObjectSetString(0,"before_S1",OBJPROP_TEXT,"0");
                     string deal_time_=TimeToString(Time_M1[barsnum_M1-1]);
                     ObjectSetString(0,"deal_time",OBJPROP_TEXT,deal_time_);
                     point1_=DoubleToString(point1,8);
                     ObjectSetString(0,"point1",OBJPROP_TEXT,point1_);
                     ObjectCreate(0,"point1t",OBJ_ARROW_THUMB_UP,0,Time_M5[point1_pos],point1);
                     point2_=DoubleToString(point2,8);
                     ObjectSetString(0,"point2",OBJPROP_TEXT,point2_);
                     ObjectCreate(0,"point2t",OBJ_ARROW_THUMB_UP,0,Time_M1[point2_pos],point2);
                     point3_=DoubleToString(point3,8);
                     ObjectSetString(0,"point3",OBJPROP_TEXT,point3_);
                     ObjectCreate(0,"point3t",OBJ_ARROW_THUMB_UP,0,Time_M1[point3_pos],point3);
                     fbuy(point1-350*d_point,vol_B0);
                     Alert("原点接");
                     return;
                  }
              }
           }
           else
           {
               if((Time_M5[ZigZagBuffer_pos_M5[2]]>order_time)&&(ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]]<order_price-300*d_point))
               {
                   if(nowp>order_price-50*d_point)
                   {
                      ObjectSetString(0,"before_S",OBJPROP_TEXT,"B");
                      ObjectSetString(0,"before_S1",OBJPROP_TEXT,"0");
                      string deal_time_=TimeToString(Time_M1[barsnum_M1-1]);
                      ObjectSetString(0,"deal_time",OBJPROP_TEXT,deal_time_);
                      point1_=DoubleToString(point1,8);
                      ObjectSetString(0,"point1",OBJPROP_TEXT,point1_);
                      ObjectCreate(0,"point1t",OBJ_ARROW_THUMB_UP,0,Time_M5[point1_pos],point1);
                      point2_=DoubleToString(point2,8);
                      ObjectSetString(0,"point2",OBJPROP_TEXT,point2_);
                      ObjectCreate(0,"point2t",OBJ_ARROW_THUMB_UP,0,Time_M1[point2_pos],point2);
                      point3_=DoubleToString(point3,8);
                      ObjectSetString(0,"point3",OBJPROP_TEXT,point3_);
                      ObjectCreate(0,"point3t",OBJ_ARROW_THUMB_UP,0,Time_M1[point3_pos],point3);
                      fbuy(point1-350*d_point,vol_B0);
                      Alert("原点接");
                      return;
                   }
               }
           }
        }
     }
}

void tradeB1()
{
     if(enable_B1==false)return;
     double vol_B1=0.44;
     if(yuanyou==true)vol_B1=4.4;
     int i,j;
     double nowp=SymbolInfoDouble(_Symbol,SYMBOL_BID);
     string point1_,time_po_,pointS_,point3;
     int dis;
     double div;
     double breakP1,breakP3,breakP4;
     double point1;
     int pos;
     double zig1;
     datetime time1;
     int flag=1;
     double point1_2to3,point2_2to3;
     string point1_2to3_,point2_2to3_;
     datetime timeS_2to3;
     string timeS_2to3_;
     double kuan;
     string kuan_;
     if(ObjectGetString(0,"before_S",OBJPROP_TEXT,0)=="0")//没有打破大通道（没有S点）//以下是找S点（当没有找到S的时候）//寻找B1开单
     {
        //以下是设置大通道的打破位置
        i=-1*big_TL-1;
        dis=LineShow_D[i][0]-LineShow_D[i][1];
        if(dis!=0)
        {
           div=High_M1[LineShow_D[i][0]]-High_M1[LineShow_D[i][1]];
           breakP4=div*(barsnum_M1-4-LineShow_D[i][0])/dis+High_M1[LineShow_D[i][0]];
           breakP3=div*(barsnum_M1-3-LineShow_D[i][0])/dis+High_M1[LineShow_D[i][0]];
           breakP1=div*(barsnum_M1-1-LineShow_D[i][0])/dis+High_M1[LineShow_D[i][0]];
           kuan=div*(LineShow_D[i][2]-LineShow_D[i][0])/dis+High_M1[LineShow_D[i][0]];
           kuan=kuan-Low_M1[LineShow_D[i][2]];
           string kuan_=DoubleToString(kuan,8);
           if(nowp>breakP1+30*d_point)
           {
              ObjectSetString(0,"before_S",OBJPROP_TEXT,"B");//标记“找到S点 B型开单”
              ObjectSetString(0,"before_S1",OBJPROP_TEXT,"1");//B1型
              pointS_=DoubleToString(nowp,8);
              ObjectSetString(0,"pointS",OBJPROP_TEXT,pointS_);
              ObjectCreate(0,"pointSt",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
              ObjectSetString(0,"B1Skuan",OBJPROP_TEXT,kuan_);
              pos=iLowest(Low_M1,barsnum_M1-LineShow_D[-1*big_TL-1][1],barsnum_M1);
              if(ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]]<ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]])
              {
                 zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
                 time1=Time_M5[ZigZagBuffer_pos_M5[1]];
              }
              else 
              {
                  zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
                  time1=Time_M5[ZigZagBuffer_pos_M5[2]];
              }
              for(i=tlines_U-1;i>=0;i--)
              {
                  if((LineShow_U[i][1]<pos+60)&&(LineShow_U[i][1]>pos-60)&&(LineShow_U[i][1]-LineShow_U[i][0]>150))break;
              }
              if(i>=0)
              {
                 if(Low_M1[LineShow_U[i][0]]<zig1)
                 {
                    point1_=DoubleToString(Low_M1[LineShow_U[i][0]],8);
                    ObjectSetString(0,"point1",OBJPROP_TEXT,point1_);
                    ObjectCreate(0,"point1t",OBJ_ARROW_THUMB_UP,0,Time_M1[LineShow_U[i][0]],Low_M1[LineShow_U[i][0]]);
                 }
                 else
                 {
                     point1_=DoubleToString(zig1,8);
                     ObjectSetString(0,"point1",OBJPROP_TEXT,point1_);
                     ObjectCreate(0,"point1t",OBJ_ARROW_THUMB_UP,0,time1,zig1);
                 }
              }
              else
              {
                  point1_=DoubleToString(zig1,8);
                  ObjectSetString(0,"point1",OBJPROP_TEXT,point1_);
                  ObjectCreate(0,"point1t",OBJ_ARROW_THUMB_UP,0,time1,zig1);
              }
              time_po_=TimeToString(Time_M1[barsnum_M1-1]);
              ObjectSetString(0,"time_po",OBJPROP_TEXT,time_po_);
              Alert("B1S");
              return;
           }
           if(High_M1[barsnum_M1-3]>breakP3+5*d_point)
           {
              if((nowp>=High_M1[barsnum_M1-2]+5*d_point)&&(High_M1[barsnum_M1-2]>High_M1[barsnum_M1-3])&&(High_M1[barsnum_M1-4]>=breakP4))
              {
                 ObjectSetString(0,"before_S",OBJPROP_TEXT,"B");//标记“找到S点 B型开单”
                 ObjectSetString(0,"before_S1",OBJPROP_TEXT,"1");//B1型
                 pointS_=DoubleToString(nowp,8);
                 ObjectSetString(0,"pointS",OBJPROP_TEXT,pointS_);
                 ObjectCreate(0,"pointSt",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                 ObjectSetString(0,"B1Skuan",OBJPROP_TEXT,kuan_);
                 pos=iLowest(Low_M1,barsnum_M1-LineShow_D[-1*big_TL-1][1],barsnum_M1);
                 if(ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]]<ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]])
                 {
                    zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
                    time1=Time_M5[ZigZagBuffer_pos_M5[1]];
                 }
                 else 
                 {
                     zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
                     time1=Time_M5[ZigZagBuffer_pos_M5[2]];
                 }
                 for(i=tlines_U-1;i>=0;i--)
                 {
                     if((LineShow_U[i][1]<pos+60)&&(LineShow_U[i][1]>pos-60)&&(LineShow_U[i][1]-LineShow_U[i][0]>150))break;
                 }
                 if(i>=0)
                 {
                    if(Low_M1[LineShow_U[i][0]]>zig1)
                    {
                       point1_=DoubleToString(Low_M1[LineShow_U[i][0]],8);
                       ObjectSetString(0,"point1",OBJPROP_TEXT,point1_);
                       ObjectCreate(0,"point1t",OBJ_ARROW_THUMB_UP,0,Time_M1[LineShow_U[i][0]],Low_M1[LineShow_U[i][0]]);
                    }
                    else
                    {
                        point1_=DoubleToString(zig1,8);
                        ObjectSetString(0,"point1",OBJPROP_TEXT,point1_);
                        ObjectCreate(0,"point1t",OBJ_ARROW_THUMB_UP,0,time1,zig1);
                    }
                 }
                 else
                 {
                     point1_=DoubleToString(zig1,8);
                     ObjectSetString(0,"point1",OBJPROP_TEXT,point1_);
                     ObjectCreate(0,"point1t",OBJ_ARROW_THUMB_UP,0,time1,zig1);
                 }
                 time_po_=TimeToString(Time_M1[barsnum_M1-1]);
                 ObjectSetString(0,"time_po",OBJPROP_TEXT,time_po_);
                 Alert("B1S");
                 return;
              }
           }
        }
     }
     if((ObjectGetString(0,"before_S",OBJPROP_TEXT,0)=="B")&&(ObjectGetString(0,"before_S1",OBJPROP_TEXT,0)=="1")) //进入B1类型，已经出现了S点
     {
         datetime time_po;
         double point1,point2,pointS,kuan;
         string point2_,point3_,deal_time_;
         point1=StringToDouble(ObjectGetString(0,"point1",OBJPROP_TEXT,0));
         pointS=StringToDouble(ObjectGetString(0,"pointS",OBJPROP_TEXT,0));
         time_po=StringToTime(ObjectGetString(0,"time_po",OBJPROP_TEXT,0));
         kuan=StringToDouble(ObjectGetString(0,"B1Skuan",OBJPROP_TEXT,0));
         if(nowp<point1)
         {
            ObjectsDeleteAll(0,0,OBJ_ARROW_THUMB_UP);
            ObjectsDeleteAll(0,0,OBJ_LABEL);
            return;
         }
         if(ObjectGetString(0,"point2",OBJPROP_TEXT,0)=="0")//没有出现2点
         {
            double zig1,zig2;
            datetime time1,time2;
            zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
            zig2=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
            time1=Time_M5[ZigZagBuffer_pos_M5[1]+2];
            time2=Time_M5[ZigZagBuffer_pos_M5[2]+2];
            int timeS=ObjectGetInteger(0,"pointSt",OBJPROP_TIME,0);
            if((zig1<zig2)&&(time2>=time_po))
            {
               point2_=DoubleToString(zig2,8);
               ObjectSetString(0,"point2",OBJPROP_TEXT,point2_);
               ObjectCreate(0,"point2t",OBJ_ARROW_THUMB_UP,0,time2,zig2);
               return;
            }
         }
         else
         {   
             double zig1,zig2;
             datetime time3;
             point2=StringToDouble(ObjectGetString(0,"point2",OBJPROP_TEXT,0));
             zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
             zig2=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
             time3=Time_M5[ZigZagBuffer_pos_M5[2]+2];
             int flag_2to3=0;
             for(i=0;i<tlines_D;i++)
             {
                 if((Time_M1[LineShow_D[i][1]]>time_po)&&(High_M1[LineShow_D[i][1]]>point2-(point2-nowp)/3))
                 {
                    flag_2to3=1; 
                    break;
                 }
             }
             if(ObjectGetString(0,"beforeS_2to3",OBJPROP_TEXT,0)=="0")
             {
                if((flag_2to3==1)&&(i<tlines_D))
                {
                   dis=LineShow_D[i][0]-LineShow_D[i][1];
                   if(dis!=0)
                   {
                      div=High_M1[LineShow_D[i][0]]-High_M1[LineShow_D[i][1]];
                      breakP1=div*(barsnum_M1-1-LineShow_D[i][0])/dis+High_M1[LineShow_D[i][0]];
                      breakP3=div*(barsnum_M1-3-LineShow_D[i][0])/dis+High_M1[LineShow_D[i][0]];
                      breakP4=div*(barsnum_M1-4-LineShow_D[i][0])/dis+High_M1[LineShow_D[i][0]];
                      if(nowp>breakP1+50*d_point)
                      {
                         timeS_2to3_=TimeToString(Time_M5[barsnum_M5-1]);
                         point1_2to3=Low_M1[iLowest(Low_M1,barsnum_M1-LineShow_D[i][1],barsnum_M1-1)];
                         point1_2to3_=DoubleToString(point1_2to3,8);
                         ObjectSetString(0,"beforeS_2to3",OBJPROP_TEXT,timeS_2to3_);
                         ObjectSetString(0,"point1_2to3",OBJPROP_TEXT,point1_2to3_);
                         ObjectCreate(0,"pointS_2to3t",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                         return;
                      }
                      if(High_M1[barsnum_M1-3]>breakP3+5*d_point)
                      {
                         if((nowp>=High_M1[barsnum_M1-2]+5*d_point)&&(High_M1[barsnum_M1-2]>High_M1[barsnum_M1-3])&&(High_M1[barsnum_M1-4]>=breakP4))
                         {
                            timeS_2to3_=TimeToString(Time_M5[barsnum_M5-1]);
                            point1_2to3=Low_M1[iLowest(Low_M1,barsnum_M1-LineShow_D[i][1],barsnum_M1-1)];
                            point1_2to3_=DoubleToString(point1_2to3,8);
                            ObjectSetString(0,"beforeS_2to3",OBJPROP_TEXT,timeS_2to3_);
                            ObjectSetString(0,"point1_2to3",OBJPROP_TEXT,point1_2to3_);
                            ObjectCreate(0,"pointS_2to3t",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                            return;
                         }
                      }
                   }
                }
             }
             else
             {
                 point1_2to3=StringToDouble(ObjectGetString(0,"point1_2to3",OBJPROP_TEXT,0));
                 if(nowp<point1_2to3)
                 {
                    ObjectDelete(0,"beforeS_2to3");
                    ObjectDelete(0,"point1_2to3");
                    ObjectDelete(0,"pointS_2to3t");
                    ObjectDelete(0,"point2_2to3");
                    ObjectDelete(0,"point2_2to3t");
                    return;
                 }
                 if(ObjectGetString(0,"point2_2to3",OBJPROP_TEXT,0)=="0")
                 {
                    point2_2to3_=DoubleToString(nowp,8);
                    ObjectSetString(0,"point2_2to3",OBJPROP_TEXT,point2_2to3_);
                    ObjectCreate(0,"point2_2to3t",OBJ_ARROW_THUMB_UP,0,Time_M5[barsnum_M5-1],nowp);
                    return;
                 }
                 else
                 {
                     point2_2to3=StringToDouble(ObjectGetString(0,"point2_2to3",OBJPROP_TEXT,0));
                     timeS_2to3=StringToTime(ObjectGetString(0,"beforeS_2to3",OBJPROP_TEXT,0));
                     if(Time_M5[barsnum_M5-2]>timeS_2to3)
                     {
                        if(High_M5[barsnum_M5-2]>point2_2to3)
                        {
                           point2_2to3_=DoubleToString(High_M5[barsnum_M5-2],8);
                           ObjectSetString(0,"point2_2to3",OBJPROP_TEXT,point2_2to3_);
                           ObjectSetDouble(0,"point2_2to3t",OBJPROP_PRICE,High_M5[barsnum_M5-2]);
                           ObjectSetInteger(0,"point2_2to3t",OBJPROP_TIME,Time_M5[barsnum_M5-2]);
                           return;
                        }
                        if((High_M5[barsnum_M5-2]<point2_2to3)&&(nowp>point2_2to3))
                        {
                           deal_time_=TimeToString(Time_M1[barsnum_M1-1]);
                           ObjectSetString(0,"deal_time",OBJPROP_TEXT,deal_time_);
                           point3_=DoubleToString(point1_2to3,8);
                           ObjectSetString(0,"point3",OBJPROP_TEXT,point3_);
                           fbuy(point1_2to3-80*d_point,vol_B1);
                           Alert("2次123进场");
                           return;
                        }
                     }
                 }
             }
             if((zig1>zig2)&&(time3>=time_po))
             {
                if(zig2<pointS)
                {
                   if((nowp>pointS+10*d_point)&&(pointS-point1>=150*d_point)&&(point2-pointS>=50*d_point))
                   {
                      //sl=findsl(nowp);
                      string deal_time_=TimeToString(Time_M1[barsnum_M1-1]);
                      ObjectSetString(0,"deal_time",OBJPROP_TEXT,deal_time_);
                      point3_=DoubleToString(zig2,8);
                      ObjectSetString(0,"point3",OBJPROP_TEXT,point3_);
                      ObjectCreate(0,"point3t",OBJ_ARROW_THUMB_UP,0,Time_M5[ZigZagBuffer_pos_M5[2]],zig2);
                      fbuy(zig2-80*d_point,vol_B1);
                      Alert("Z字线123进场");
                      return;
                   }
                }
                else
                {
                    if(nowp>point2+10*d_point)
                    {
                       string deal_time_=TimeToString(Time_M1[barsnum_M1-1]);
                       ObjectSetString(0,"deal_time",OBJPROP_TEXT,deal_time_);
                       point3_=DoubleToString(zig2,8);
                       ObjectSetString(0,"point3",OBJPROP_TEXT,point3_);
                       ObjectCreate(0,"point3t",OBJ_ARROW_THUMB_UP,0,Time_M5[ZigZagBuffer_pos_M5[2]],zig2);
                       fbuy(zig2-80*d_point,vol_B1);
                       Alert("Z字线123进场");
                       return;
                    }
                }
             }
         }
     }
}

void tradeB2()
{
     if(enable_B2==false)return;
     double vol_B2=0.42;
     if(yuanyou==true)vol_B2=4.2;
     int i,j;
     double nowp=SymbolInfoDouble(_Symbol,SYMBOL_BID);
     string point1_,time_po_,pointS_;
     int dis;
     double div;
     double breakP1,breakP3,breakP4,breakP11;
     double kuan;
     string kuan_;
     int flag=1;
     double point1_2to3,point2_2to3;
     string point1_2to3_,point2_2to3_;
     datetime timeS_2to3;
     string timeS_2to3_;
     if(ObjectGetString(0,"before_S",OBJPROP_TEXT,0)=="0")
     {
        //以下是设置中通道的打破位置
        i=-1*middle_TL-1;
        dis=LineShow_U[i][0]-LineShow_U[i][1];
        dis=LineShow_D[i][0]-LineShow_D[i][1];
        if(dis!=0)
        {
           div=High_M1[LineShow_D[i][0]]-High_M1[LineShow_D[i][1]];
           breakP4=div*(barsnum_M1-4-LineShow_D[i][0])/dis+High_M1[LineShow_D[i][0]];
           breakP3=div*(barsnum_M1-3-LineShow_D[i][0])/dis+High_M1[LineShow_D[i][0]];
           breakP1=div*(barsnum_M1-1-LineShow_D[i][0])/dis+High_M1[LineShow_D[i][0]];
           if(i<tlines_D-1)
           {
              dis=LineShow_D[i+1][0]-LineShow_D[i+1][1];
              if(dis!=0)
              {
                 div=High_M1[LineShow_D[i+1][0]]-High_M1[LineShow_D[i+1][1]];
                 breakP11=div*(barsnum_M1-1-LineShow_D[i+1][0])/dis+High_M1[LineShow_D[i+1][0]];
                 if(breakP11<breakP1+300*d_point)flag=0;
              }
           }
           if(flag==1)
           {
              kuan=div*(LineShow_D[i][2]-LineShow_D[i][0])/dis+High_M1[LineShow_D[i][0]];
              kuan=kuan-Low_M1[LineShow_D[i][2]];
              kuan_=DoubleToString(kuan,8);
              if(nowp>breakP1+30*d_point)
              {
                 ObjectSetString(0,"before_S",OBJPROP_TEXT,"B");//标记“找到S点 B型开单”
                 ObjectSetString(0,"before_S1",OBJPROP_TEXT,"2");//B2型
                 pointS_=DoubleToString(breakP1,8);
                 ObjectSetString(0,"pointS",OBJPROP_TEXT,pointS_);
                 ObjectCreate(0,"pointSt",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                 ObjectSetString(0,"B1Skuan",OBJPROP_TEXT,kuan_);
                 findperiod1();
                 Alert("B2S");
                 return;
              }
              if(High_M1[barsnum_M1-3]>breakP3+5*d_point)
              {
                 if((nowp>=High_M1[barsnum_M1-2]+5*d_point)&&(High_M1[barsnum_M1-2]>High_M1[barsnum_M1-3])&&(High_M1[barsnum_M1-4]>=breakP4))
                 {
                    ObjectSetString(0,"before_S",OBJPROP_TEXT,"B");//标记“找到S点 B型开单”
                    ObjectSetString(0,"before_S1",OBJPROP_TEXT,"2");//B2型
                    pointS_=DoubleToString(breakP1,8);
                    ObjectSetString(0,"pointS",OBJPROP_TEXT,pointS_);
                    ObjectCreate(0,"pointSt",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                    ObjectSetString(0,"B1Skuan",OBJPROP_TEXT,kuan_);
                    findperiod1();
                    Alert("B2S");
                    return;
                 }
              }
           }
        }
     }
     if((ObjectGetString(0,"before_S",OBJPROP_TEXT,0)=="B")&&(ObjectGetString(0,"before_S1",OBJPROP_TEXT,0)=="2")) //B2型
     {
         datetime time_po;
         double point1,point2,pointS,kuan;
         string point2_,point3_,deal_time_;
         point1=StringToDouble(ObjectGetString(0,"point1",OBJPROP_TEXT,0));
         pointS=StringToDouble(ObjectGetString(0,"pointS",OBJPROP_TEXT,0));
         time_po=StringToTime(ObjectGetString(0,"time_po",OBJPROP_TEXT,0));
         kuan=StringToDouble(ObjectGetString(0,"B1Skuan",OBJPROP_TEXT,0));
         flag=1;
         if((middle_TL<0)&&(-1*middle_TL<=tlines_D))
         {
            i=-1*middle_TL-1;
            dis=LineShow_D[i][0]-LineShow_D[i][1];
         }
         else dis=0;
         if(dis!=0)
         {
            div=High_M1[LineShow_D[i][0]]-High_M1[LineShow_D[i][1]];
            breakP4=div*(barsnum_M1-4-LineShow_D[i][0])/dis+High_M1[LineShow_D[i][0]];
            breakP3=div*(barsnum_M1-3-LineShow_D[i][0])/dis+High_M1[LineShow_D[i][0]];
            breakP1=div*(barsnum_M1-1-LineShow_D[i][0])/dis+High_M1[LineShow_D[i][0]];
            if(i<tlines_D-1)
            {
              dis=LineShow_D[i+1][0]-LineShow_D[i+1][1];
              if(dis!=0)
              {
                 div=High_M1[LineShow_D[i+1][0]]-High_M1[LineShow_D[i+1][1]];
                 breakP11=div*(barsnum_M1-1-LineShow_D[i+1][0])/dis+High_M1[LineShow_D[i+1][0]];
                 if(breakP11<breakP1+(pointS-point1)*1.5)
                 {
                    flag=0;
                    if(nowp>breakP11+50*d_point)
                    {
                       pointS_=DoubleToString(breakP1,8);
                       ObjectSetString(0,"pointS",OBJPROP_TEXT,pointS_);
                       ObjectDelete(0,"pointSt");
                       ObjectCreate(0,"pointSt",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP11);
                       time_po_=TimeToString(Time_M1[barsnum_M1-1]);
                       ObjectSetString(0,"time_po",OBJPROP_TEXT,time_po_);
                       if(i+1==-1*big_TL-1)
                       {
                          ObjectSetString(0,"before_S1",OBJPROP_TEXT,"2");
                       }
                       if(ObjectGetString(0,"point2",OBJPROP_TEXT,0)!="0")
                       {
                          ObjectDelete(0,"point2");
                          ObjectDelete(0,"point2t");
                       }
                       return;
                    }
                 }
              }
            }
         }
         if(nowp<point1)
         {
            ObjectsDeleteAll(0,0,OBJ_ARROW_THUMB_UP);
            ObjectsDeleteAll(0,0,OBJ_LABEL);
            return;
         }
         if(ObjectGetString(0,"point2",OBJPROP_TEXT,0)=="0")//没有出现2点
         {
            double zig1,zig2;
            datetime time1,time2;
            zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
            zig2=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
            time1=Time_M5[ZigZagBuffer_pos_M5[1]+2];
            time2=Time_M5[ZigZagBuffer_pos_M5[2]+2];
            int timeS=ObjectGetInteger(0,"pointSt",OBJPROP_TIME,0);
            if((zig1<zig2)&&(time2>=time_po))
            {
               point2_=DoubleToString(zig2,8);
               ObjectSetString(0,"point2",OBJPROP_TEXT,point2_);
               ObjectCreate(0,"point2t",OBJ_ARROW_THUMB_UP,0,time2,zig2);
               return;
            }
         }
         else
         {   
             double zig1,zig2;
             datetime time3;
             point2=StringToDouble(ObjectGetString(0,"point2",OBJPROP_TEXT,0));
             zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
             zig2=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
             time3=Time_M5[ZigZagBuffer_pos_M5[2]+2];
             int flag_2to3=0;
             for(i=0;i<tlines_U;i++)
             {
                 if((Time_M1[LineShow_D[i][1]]>time_po)&&(High_M1[LineShow_D[i][1]]>point2-(point2-nowp)/3))
                 {
                    flag_2to3=1; 
                    break;
                 }
             }
             if(ObjectGetString(0,"beforeS_2to3",OBJPROP_TEXT,0)=="0")
             {
                if((flag_2to3==1)&&(i<tlines_D))
                {
                   dis=LineShow_D[i][0]-LineShow_D[i][1];
                   if(dis!=0)
                   {
                      div=High_M1[LineShow_D[i][0]]-High_M1[LineShow_D[i][1]];
                      breakP1=div*(barsnum_M1-1-LineShow_D[i][0])/dis+High_M1[LineShow_D[i][0]];
                      breakP3=div*(barsnum_M1-3-LineShow_D[i][0])/dis+High_M1[LineShow_D[i][0]];
                      breakP4=div*(barsnum_M1-4-LineShow_D[i][0])/dis+High_M1[LineShow_D[i][0]];
                      if(nowp>breakP1+50*d_point)
                      {
                         timeS_2to3_=TimeToString(Time_M5[barsnum_M5-1]);
                         point1_2to3=Low_M1[iLowest(Low_M1,barsnum_M1-LineShow_D[i][1],barsnum_M1-1)];
                         point1_2to3_=DoubleToString(point1_2to3,8);
                         ObjectSetString(0,"beforeS_2to3",OBJPROP_TEXT,timeS_2to3_);
                         ObjectSetString(0,"point1_2to3",OBJPROP_TEXT,point1_2to3_);
                         ObjectCreate(0,"pointS_2to3t",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                         return;
                      }
                      if(High_M1[barsnum_M1-3]>breakP3+5*d_point)
                      {
                         if((nowp>=High_M1[barsnum_M1-2]+5*d_point)&&(High_M1[barsnum_M1-2]>High_M1[barsnum_M1-3])&&(High_M1[barsnum_M1-4]>=breakP4))
                         {
                            timeS_2to3_=TimeToString(Time_M5[barsnum_M5-1]);
                            point1_2to3=Low_M1[iLowest(Low_M1,barsnum_M1-LineShow_D[i][1],barsnum_M1-1)];
                            point1_2to3_=DoubleToString(point1_2to3,8);
                            ObjectSetString(0,"beforeS_2to3",OBJPROP_TEXT,timeS_2to3_);
                            ObjectSetString(0,"point1_2to3",OBJPROP_TEXT,point1_2to3_);
                            ObjectCreate(0,"pointS_2to3t",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                            return;
                         }
                      }
                   }
                }
             }
             else
             {
                 point1_2to3=StringToDouble(ObjectGetString(0,"point1_2to3",OBJPROP_TEXT,0));
                 if(nowp<point1_2to3)
                 {
                    ObjectDelete(0,"beforeS_2to3");
                    ObjectDelete(0,"point1_2to3");
                    ObjectDelete(0,"pointS_2to3t");
                    ObjectDelete(0,"point2_2to3");
                    ObjectDelete(0,"point2_2to3t");
                    return;
                 }
                 if(ObjectGetString(0,"point2_2to3",OBJPROP_TEXT,0)=="0")
                 {
                    point2_2to3_=DoubleToString(nowp,8);
                    ObjectSetString(0,"point2_2to3",OBJPROP_TEXT,point2_2to3_);
                    ObjectCreate(0,"point2_2to3t",OBJ_ARROW_THUMB_UP,0,Time_M5[barsnum_M5-1],nowp);
                    return;
                 }
                 else
                 {
                     point2_2to3=StringToDouble(ObjectGetString(0,"point2_2to3",OBJPROP_TEXT,0));
                     timeS_2to3=StringToTime(ObjectGetString(0,"beforeS_2to3",OBJPROP_TEXT,0));
                     if(Time_M5[barsnum_M5-2]>timeS_2to3)
                     {
                        if(High_M5[barsnum_M5-2]>point2_2to3)
                        {
                           point2_2to3_=DoubleToString(High_M5[barsnum_M5-2],8);
                           ObjectSetString(0,"point2_2to3",OBJPROP_TEXT,point2_2to3_);
                           ObjectSetDouble(0,"point2_2to3t",OBJPROP_PRICE,High_M5[barsnum_M5-2]);
                           ObjectSetInteger(0,"point2_2to3t",OBJPROP_TIME,Time_M5[barsnum_M5-2]);
                           return;
                        }
                        if((High_M5[barsnum_M5-2]<point2_2to3)&&(nowp>point2_2to3))
                        {
                           deal_time_=TimeToString(Time_M1[barsnum_M1-1]);
                           ObjectSetString(0,"deal_time",OBJPROP_TEXT,deal_time_);
                           point3_=DoubleToString(point1_2to3,8);
                           ObjectSetString(0,"point3",OBJPROP_TEXT,point3_);
                           fbuy(point1_2to3-80*d_point,vol_B2);
                           Alert("2次123进场");
                           return;
                        }
                     }
                 }
             }
             if((zig1>zig2)&&(time3>=time_po))
             {
                if(zig2<pointS)
                {
                   if((nowp>pointS+10*d_point)&&(pointS-point1>=150*d_point)&&(point2-pointS>=50*d_point)&&(flag==1))
                   {
                      //sl=findsl(nowp);
                      string deal_time_=TimeToString(Time_M1[barsnum_M1-1]);
                      ObjectSetString(0,"deal_time",OBJPROP_TEXT,deal_time_);
                      point3_=DoubleToString(zig2,8);
                      ObjectSetString(0,"point3",OBJPROP_TEXT,point3_);
                      fbuy(zig2-80*d_point,vol_B2);
                      Alert("Z字线进场");
                      return;
                   }
                }
                else
                {
                    if((nowp<point2-10*d_point)&&(flag==1))
                    {
                       string deal_time_=TimeToString(Time_M1[barsnum_M1-1]);
                       ObjectSetString(0,"deal_time",OBJPROP_TEXT,deal_time_);
                       point3_=DoubleToString(zig2,8);
                       ObjectSetString(0,"point3",OBJPROP_TEXT,point3_);
                       fbuy(zig2-80*d_point,vol_B2);
                       Alert("Z字线进场");
                       return;
                    }
                }
             }
         }
     }
}

void tradeB3()
{
     if(enable_B3==false)return;
     double vol_B3=0.36;
     if(yuanyou==true)vol_B3=3.6;
     int i;
     double nowp=SymbolInfoDouble(_Symbol,SYMBOL_BID);
     double point1,point2,point3;
     string point1_,point2_,point3_;
     int point1_pos,point2_pos,point3_pos,pointh_pos;
     int tmp_big_TL;
     datetime nowtime=SymbolInfoInteger(_Symbol,SYMBOL_TIME);//当前时间
     HistorySelect(Time_D1[barsnum_D1-15],nowtime);
     int order_num=HistoryOrdersTotal();//选择的历史区间内总交易次数
     int ticket=HistoryOrderGetTicket(order_num-1);//这是上一个单的ticket
     datetime order_time=HistoryOrderGetInteger(ticket,ORDER_TIME_DONE);
     ObjectSetString(0,"point_ag_time",OBJPROP_TEXT,"1");
     if(big_TL>0)
     {
        int tmp_big_TL=big_TL;
        if(Time_M1[LineShow_U[tmp_big_TL-1][1]]>order_time)return;
        point2_pos=iHighest(High_M1,barsnum_M1-LineShow_U[tmp_big_TL-1][1],barsnum_M1-5);
        point2=High_M1[point2_pos];
        if(ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]]<ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]])
        {
           for(i=1;i<=13;i=i+2)
           {
               if(Time_M5[ZigZagBuffer_pos_M5[i]]<Time_M1[point2_pos])
               {
                  point1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[i]];
                  point1_pos=ZigZagBuffer_pos_M5[i];
                  break;
               }
           }
           point1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[i]];
           point1_pos=ZigZagBuffer_pos_M5[i];
        }
        else
        {
            for(i=2;i<=14;i=i+2)
            {
                if(Time_M5[ZigZagBuffer_pos_M5[i]]<Time_M1[point2_pos])
                {
                   point1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[i]];
                   point1_pos=ZigZagBuffer_pos_M5[i];
                   break;
                }
            }
            point1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[i]];
            point1_pos=ZigZagBuffer_pos_M5[i];
        }
        point3_pos=iLowest(Low_M1,barsnum_M1-point2_pos,barsnum_M1-3);
        point3=Low_M1[point3_pos];
     }
     else
     {
         tmp_big_TL=big_TL;
         pointh_pos=iLowest(Low_M1,barsnum_M1-LineShow_D[-1*tmp_big_TL-1][0],barsnum_M1-5);
         if(ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]]>ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]])
         {
            if(Time_M1[pointh_pos]>Time_M5[ZigZagBuffer_pos_M5[3]])return;
         }
         else
         {
             if(Time_M1[pointh_pos]>Time_M5[ZigZagBuffer_pos_M5[2]])return;
         }
         point2_pos=iHighest(High_M1,barsnum_M1-pointh_pos,barsnum_M1-5);
         point2=High_M1[point2_pos];
         if(ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]]<ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]])
         {
            for(i=1;i<=13;i=i+2)
            {
                if(Time_M5[ZigZagBuffer_pos_M5[i]]<Time_M1[point2_pos])
                {
                   point1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[i]];
                   point1_pos=ZigZagBuffer_pos_M5[i];
                   break;
                }
            }
            point1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[i]];
            point1_pos=ZigZagBuffer_pos_M5[i];
         }
         else
         {
             for(i=2;i<=14;i=i+2)
             {
                 if(Time_M5[ZigZagBuffer_pos_M5[i]]<Time_M1[point2_pos])
                 {
                    point1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[i]];
                    point1_pos=ZigZagBuffer_pos_M5[i];
                    break;
                 }
             }
             point1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[i]];
             point1_pos=ZigZagBuffer_pos_M5[i];
         }
         point3_pos=iLowest(Low_M1,barsnum_M1-point2_pos,barsnum_M1-3);
         point3=Low_M1[point3_pos];
     }
     if(point3<point1+50*d_point)//3比1高
     {
        return;
     }
     if(ObjectFind(0,"B3point2t")<0)
     {
        ObjectCreate(0,"B3point2t",OBJ_ARROW_THUMB_DOWN,0,Time_M1[point2_pos],point2);
     }
     else
     {
         if(ObjectGetDouble(0,"B3point2t",OBJPROP_PRICE,0)!=point2)
            ObjectSetDouble(0,"B3point2t",OBJPROP_PRICE,point2);
            ObjectSetInteger(0,"B3point2t",OBJPROP_TIME,Time_M1[point2_pos]);
     }
     if(nowp>point2+10*d_point)
     {
        ObjectSetString(0,"before_S",OBJPROP_TEXT,"B");
        ObjectSetString(0,"before_S1",OBJPROP_TEXT,"3");
        string deal_time_=TimeToString(Time_M1[barsnum_M1-1]);
        ObjectSetString(0,"deal_time",OBJPROP_TEXT,deal_time_);
        point1_=DoubleToString(point1,8);
        ObjectSetString(0,"point1",OBJPROP_TEXT,point1_);
        ObjectCreate(0,"point1t",OBJ_ARROW_THUMB_UP,0,Time_M5[point1_pos],point1);
        point2_=DoubleToString(point2,8);
        ObjectSetString(0,"point2",OBJPROP_TEXT,point2_);
        ObjectCreate(0,"point2t",OBJ_ARROW_THUMB_UP,0,Time_M1[point2_pos],point2);
        point3_=DoubleToString(point3,8);
        ObjectSetString(0,"point3",OBJPROP_TEXT,point3_);
        ObjectCreate(0,"point3t",OBJ_ARROW_THUMB_UP,0,Time_M1[point3_pos],point3);
        fbuy(point1-250*d_point,vol_B3);
        Alert("B3开单");
        return;
     }
}

/*
void tradeB1buy()
{
     int i,j;
     double nowp=SymbolInfoDouble(_Symbol,SYMBOL_BID);
     string point1_,time_po_,pointS_;
     int dis;
     double div;
     double breakP1,breakP3,breakP4;
     string vol_,sl_,nowp_;
     if(ObjectGetString(0,"before_S",OBJPROP_TEXT,0)=="0")//没有打破大通道（没有S点）//以下是找S点（当没有找到S的时候）//寻找B1开单
     {
        //以下是设置大通道的打破位置
        if(big_TL>0)return;
        i=-1*big_TL-1;
        dis=LineShow_D[i][0]-LineShow_D[i][1];
        if(dis==0)return;
        div=High_M5[LineShow_D[i][0]]-High_M5[LineShow_D[i][1]];
        breakP4=div*(barsnum_M5-4-LineShow_D[i][0])/dis+High_M5[LineShow_D[i][0]];
        breakP3=div*(barsnum_M5-3-LineShow_D[i][0])/dis+High_M5[LineShow_D[i][0]];
        breakP1=div*(barsnum_M5-1-LineShow_D[i][0])/dis+High_M5[LineShow_D[i][0]];
        if(nowp>breakP1+0.03)
        {
           ObjectSetString(0,"before_S",OBJPROP_TEXT,"B");//标记“找到S点 B型开单”
           ObjectSetString(0,"before_S1",OBJPROP_TEXT,"1");//B1型
           pointS_=DoubleToString(nowp,8);
           ObjectSetString(0,"pointS",OBJPROP_TEXT,pointS_);
           ObjectCreate(0,"pointSt",OBJ_ARROW_THUMB_UP,0,Time_M5[barsnum_M5-1],breakP1);
           findperiod1();
           return;
        }
        if(High_M5[barsnum_M5-3]>breakP3+0.005)
        {
           if((nowp>=High_M5[barsnum_M5-2]+0.005)&&(High_M5[barsnum_M5-2]>High_M5[barsnum_M5-3])&&(High_M5[barsnum_M5-4]<=breakP4))
           {
              ObjectSetString(0,"before_S",OBJPROP_TEXT,"B");//标记“找到S点 B型开单”
              ObjectSetString(0,"before_S1",OBJPROP_TEXT,"3");//B1型多单
              pointS_=DoubleToString(nowp,8);
              ObjectSetString(0,"pointS",OBJPROP_TEXT,pointS_);
              ObjectCreate(0,"pointSt",OBJ_ARROW_THUMB_UP,0,Time_M5[barsnum_M5-1],breakP1);
              findperiod1();
              return;
           }
        }
     }
     if((ObjectGetString(0,"before_S",OBJPROP_TEXT,0)=="B")&&(ObjectGetString(0,"before_S1",OBJPROP_TEXT,0)=="3")) //进入B1多单类型，已经出现了S点
     {
         datetime time_po;
         double point1,point2,pointS;
         string point2_,point3_,deal_time_;
         point1=StringToDouble(ObjectGetString(0,"point1",OBJPROP_TEXT,0));
         pointS=StringToDouble(ObjectGetString(0,"pointS",OBJPROP_TEXT,0));
         time_po=StringToTime(ObjectGetString(0,"time_po",OBJPROP_TEXT,0));
         if(nowp<point1)
         {
            ObjectsDeleteAll(0,0,OBJ_ARROW_THUMB_UP);
            ObjectsDeleteAll(0,0,OBJ_LABEL);
            return;
         }
         int period;
         period=StringToInteger(ObjectGetString(0,"trade_period",OBJPROP_TEXT,0));
         if(ObjectGetString(0,"point2",OBJPROP_TEXT,0)=="0")//没有出现2点
         {
            double zig1,zig2;
            datetime time1,time2;
            if(period==1)
            {
               zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
               zig2=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
               time1=Time_M5[ZigZagBuffer_pos_M5[1]];
               time2=Time_M5[ZigZagBuffer_pos_M5[2]];
            }
            if(period==2)
            {
               zig1=ZigZagBuffer_M15[ZigZagBuffer_pos_M15[1]];
               zig2=ZigZagBuffer_M15[ZigZagBuffer_pos_M15[2]];
               time1=Time_M15[ZigZagBuffer_pos_M15[1]];
               time2=Time_M15[ZigZagBuffer_pos_M15[2]];
            }
            if(period==3)
            {
               zig1=ZigZagBuffer_M30[ZigZagBuffer_pos_M30[1]];
               zig2=ZigZagBuffer_M30[ZigZagBuffer_pos_M30[2]];
               time1=Time_M30[ZigZagBuffer_pos_M30[1]];
               time2=Time_M30[ZigZagBuffer_pos_M30[2]];
            }
            if(period==4)
            {
               zig1=ZigZagBuffer_H1[ZigZagBuffer_pos_H1[1]];
               zig2=ZigZagBuffer_H1[ZigZagBuffer_pos_H1[2]];
               time1=Time_H1[ZigZagBuffer_pos_H1[1]];
               time2=Time_H1[ZigZagBuffer_pos_H1[2]];
            }
            if((zig1<zig2)&&(time1>=time_po))
            {
               point2_=DoubleToString(zig2,8);
               ObjectSetString(0,"point2",OBJPROP_TEXT,point2_);
               ObjectCreate(0,"point2t",OBJ_ARROW_THUMB_UP,0,time2,zig2);
               return;
            }
         }
         else
         {   
             double zig1,zig2;
             datetime time3;
             point2=StringToDouble(ObjectGetString(0,"point2",OBJPROP_TEXT,0));
             if(period==1)
             {
                zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
                zig2=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
                time3=Time_M5[ZigZagBuffer_pos_M5[2]];
             }
             if(period==2)
             {
                zig1=ZigZagBuffer_M15[ZigZagBuffer_pos_M15[1]];
                zig2=ZigZagBuffer_M15[ZigZagBuffer_pos_M15[2]];
                time3=Time_M15[ZigZagBuffer_pos_M15[2]];
             }
             if(period==3)
             {
                zig1=ZigZagBuffer_M30[ZigZagBuffer_pos_M30[1]];
                zig2=ZigZagBuffer_M30[ZigZagBuffer_pos_M30[2]];
                time3=Time_M30[ZigZagBuffer_pos_M30[2]];
             }
             if(period==4)
             {
                zig1=ZigZagBuffer_H1[ZigZagBuffer_pos_H1[1]];
                zig2=ZigZagBuffer_H1[ZigZagBuffer_pos_H1[2]];
                time3=Time_H1[ZigZagBuffer_pos_H1[2]];
             }
             if(zig2<pointS)
             {
                if((zig1>zig2)&&(time3>=time_po))
                {
                   if(nowp>pointS+0.01)
                   {
                      string deal_time_=TimeToString(Time_M5[barsnum_M5-1]);
                      ObjectSetString(0,"deal_time",OBJPROP_TEXT,deal_time_);
                      point3_=DoubleToString(zig2,8);
                      ObjectSetString(0,"point3",OBJPROP_TEXT,point3_);
                      ObjectSetString(0,"B1buy",OBJPROP_TEXT,"1");
                      vol_=DoubleToString(0.4,8);
                      ObjectSetString(0,"B1buyvol",OBJPROP_TEXT,vol_);
                      sl_=DoubleToString(findslB1buy(),8);
                      ObjectSetString(0,"B1buysl",OBJPROP_TEXT,sl_);
                      nowp_=DoubleToString(nowp,8);
                      ObjectSetString(0,"B1buypoint",OBJPROP_TEXT,nowp_);
                      return;
                   }
                }
             }
             else
             {
                 if(nowp>point2+0.01)
                 {
                    string deal_time_=TimeToString(Time_M5[barsnum_M5-1]);
                    ObjectSetString(0,"deal_time",OBJPROP_TEXT,deal_time_);
                    point3_=DoubleToString(zig2,8);
                    ObjectSetString(0,"point3",OBJPROP_TEXT,point3_);
                    ObjectSetString(0,"B1buy",OBJPROP_TEXT,"1");
                    vol_=DoubleToString(0.4,8);
                    ObjectSetString(0,"B1buyvol",OBJPROP_TEXT,vol_);
                    sl_=DoubleToString(findslB1buy(),8);
                    ObjectSetString(0,"B1buysl",OBJPROP_TEXT,sl_);
                    nowp_=DoubleToString(nowp,8);
                    ObjectSetString(0,"B1buypoint",OBJPROP_TEXT,nowp_);
                    return;
                 }
             }
         }
     }
     if((ObjectGetString(0,"before_S",OBJPROP_TEXT,0)=="B")&&(ObjectGetString(0,"before_S1",OBJPROP_TEXT,0)=="2"))//B2型
     {
        
     }
}
*/
/*
void trade_ag()//接单
{
     double nowp=SymbolInfoDouble(_Symbol,SYMBOL_BID);
     datetime nowtime=SymbolInfoInteger(_Symbol,SYMBOL_TIME);//当前时间
     HistorySelect(Time_D1[barsnum_D1-30],nowtime);
     int order_num=HistoryOrdersTotal();//选择的历史区间内总交易次数
     int ticket=HistoryOrderGetTicket(order_num-1);//这是选择订单的ticket
     datetime last_deal_time=HistoryOrderGetInteger(ticket,ORDER_TIME_DONE);
     double point_ag;
     datetime point_ag_time=StringToTime(ObjectGetString(0,"point_ag_time",OBJPROP_TEXT,0));
     string point_ag_time_;
     string point1_;
     int i;
     double point_ag1,point_ag3;
     int point_ag3_pos;
     string time_po_;
     double out;
     //如果盈利，找到2点
     if(order_num>0)
     {
        i=order_num-1;
        ticket=HistoryOrderGetTicket(i);
        out=HistoryOrderGetDouble(ticket,ORDER_PRICE_OPEN);
        i=order_num-2;
        while(i>=0)
        {
              ticket=HistoryOrderGetTicket(i);
              if(HistoryOrderGetInteger(ticket,ORDER_TYPE)==ORDER_TYPE_SELL)break;
              i--;
        }
        if(HistoryOrderGetDouble(ticket,ORDER_PRICE_OPEN)>out)
        {
           if(ZigZagBuffer_H1[ZigZagBuffer_pos_H1[1]]<ZigZagBuffer_H1[ZigZagBuffer_pos_H1[2]])
           {
              for(i=1;1<=13;i=i+2)
              {
                  if(Time_H1[ZigZagBuffer_pos_H1[i]]<last_deal_time)
                  {
                     point_ag_time=Time_H1[ZigZagBuffer_pos_H1[i]];
                     break;
                  }
              }
           }
           else
           {
              for(i=2;1<=14;i=i+2)
              {
                  if(Time_H1[ZigZagBuffer_pos_H1[i]]<last_deal_time)
                  {
                     point_ag_time=Time_H1[ZigZagBuffer_pos_H1[i]];
                     break;
                  }
              }
           }
           if((ObjectGetString(0,"point_ag_time",OBJPROP_TEXT,0)=="0")||(Time_H1[ZigZagBuffer_pos_H1[i]]>point_ag_time))
           {
              point_ag_time_=TimeToString(point_ag_time);
              ObjectSetString(0,"point_ag_time",OBJPROP_TEXT,point_ag_time_);
           }
           point_ag_time=StringToTime(ObjectGetString(0,"point_ag_time",OBJPROP_TEXT,0));
        }
     }
     if(ObjectGetString(0,"point_ag_time",OBJPROP_TEXT,0)=="0")return;
     for(i=barsnum_H1-3;i>=barsnum_H1-300;i--)
     {
         if(Time_H1[i]<=point_ag_time)break;
     }
     if(i>barsnum_H1-300)point_ag=Low_H1[i];
     else point_ag=0;
     //寻找3点
     point_ag3_pos=iHighest(High_H1,barsnum_H1-i,barsnum_H1-1);
     point_ag3=High_H1[point_ag3_pos];
     //破2点接
     if((nowp<point_ag-0.01)&&(point_ag>0))//破了2点
     {
        //寻找1点
        if(ZigZagBuffer_H1[ZigZagBuffer_pos_H1[1]]>ZigZagBuffer_H1[ZigZagBuffer_pos_H1[2]])
        {
           for(i=3;i<=13;i=i+2)
           {
               if(Time_H1[ZigZagBuffer_pos_H1[i]]<point_ag_time)
               {
                  point_ag1=High_H1[ZigZagBuffer_pos_H1[i]];
                  break;
               }
           }
        }
        else
        {
            for(i=4;i<=14;i=i+2)
            {
                if(Time_H1[ZigZagBuffer_pos_H1[i]]<point_ag_time)
                {
                   point_ag1=High_H1[ZigZagBuffer_pos_H1[i]];
                   break;
                }
            }
        }
        //3点需要比1点低
        if(point_ag3<point_ag1)
        {
           fsell((point_ag1+0.15),0.4);
           if(point_ag3<nowp+0.25)point_ag3=nowp+0.25;
           point1_=DoubleToString(point_ag3,8);
           ObjectSetString(0,"point1",OBJPROP_TEXT,point1_);
           ObjectCreate(0,"point1t",OBJ_ARROW_THUMB_UP,0,Time_H1[point_ag3_pos],point_ag3);
           ObjectSetString(0,"before_S",OBJPROP_TEXT,"A");
           ObjectSetString(0,"before_S1",OBJPROP_TEXT,"2");
           ObjectSetString(0,"trade_period",OBJPROP_TEXT,"4");
           time_po_=TimeToString(Time_H1[barsnum_H1-1]);
           ObjectSetString(0,"time_po",OBJPROP_TEXT,time_po_);
           return;
        }
     }
     //在大通道上沿or破通道接
     i=-1*big_TL-1;
     int dis=LineShow_D[i][0]-LineShow_D[i][1];
     if(dis==0)return;
     double div=High_M5[LineShow_D[i][0]]-High_M5[LineShow_D[i][1]];
     double breakP1=div*(barsnum_M5-1-LineShow_U[i][0])/dis+Low_M5[LineShow_U[i][0]];
     int bar2=LineShow_D[i][2];
     double bar2_value=ObjectGetValueByTime(0,NameTL_D+(i+1),Time_M5[bar2],0);
     double kuan=High_M5[bar2]-bar2_value;
     if((nowp>breakP1-kuan*0.25)&&(point_ag3>point_ag+0.25))
     {
        //寻找1点
        if(ZigZagBuffer_H1[ZigZagBuffer_pos_H1[1]]>ZigZagBuffer_H1[ZigZagBuffer_pos_H1[2]])
        {
           for(i=3;i<=13;i=i+2)
           {
               if(Time_H1[ZigZagBuffer_pos_H1[i]]<point_ag_time)
               {
                  point_ag1=High_H1[ZigZagBuffer_pos_H1[i]];
                  break;
               }
           }
        }
        else
        {
            for(i=4;i<=14;i=i+2)
            {
                if(Time_H1[ZigZagBuffer_pos_H1[i]]<point_ag_time)
                {
                   point_ag1=High_H1[ZigZagBuffer_pos_H1[i]];
                   break;
                }
            }
        }
        if((point_ag1>point_ag3)&&(ZigZagBuffer_M30[ZigZagBuffer_pos_M30[1]]<point_ag3)&&(Time_M30[ZigZagBuffer_pos_M30[1]]>Time_H1[point_ag3_pos]))
        {
           fsell((point_ag1+0.20),0.4);
           if(point_ag1<nowp+0.25)point_ag1=nowp+0.25;
           point1_=DoubleToString(point_ag1,8);
           ObjectSetString(0,"point1",OBJPROP_TEXT,point1_);
           ObjectCreate(0,"point1t",OBJ_ARROW_THUMB_UP,0,Time_H1[ZigZagBuffer_pos_H1[i]],point_ag1);
           ObjectSetString(0,"before_S",OBJPROP_TEXT,"A");
           ObjectSetString(0,"before_S1",OBJPROP_TEXT,"2");
           ObjectSetString(0,"trade_period",OBJPROP_TEXT,"4");
           time_po_=TimeToString(Time_H1[barsnum_H1-1]);
           ObjectSetString(0,"time_po",OBJPROP_TEXT,time_po_);
           return;
        }
     }
     return;
}
*/
void escape()
{
     if(ObjectGetString(0,"before_S",OBJPROP_TEXT,0)=="A")
     {
        if(ObjectGetString(0,"before_S1",OBJPROP_TEXT,0)=="1")escapeA1();
        if(ObjectGetString(0,"before_S1",OBJPROP_TEXT,0)=="2")escapeA2();
     }
     if(ObjectGetString(0,"before_S",OBJPROP_TEXT,0)=="B")
     {
        if(ObjectGetString(0,"before_S1",OBJPROP_TEXT,0)=="0")escapeB0();
        if(ObjectGetString(0,"before_S1",OBJPROP_TEXT,0)=="1")escapeB1();
        if(ObjectGetString(0,"before_S1",OBJPROP_TEXT,0)=="2")escapeB2();
        if(ObjectGetString(0,"before_S1",OBJPROP_TEXT,0)=="3")escapeB3();
     }
}

void escapeA1()
{
     double vol_full=0.40;
     if(yuanyou==true)vol_full=4;
     double point1,point2,point3;
     string point1_,point2_,point3_;
     datetime point1_po;
     string point1_po_;
     int point1_pos=0,point3_pos=0;
     string point1_pos_,point3_pos_;
     point1=StringToDouble(ObjectGetString(0,"point1",OBJPROP_TEXT,0));
     point2=StringToDouble(ObjectGetString(0,"point2",OBJPROP_TEXT,0));
     point3=StringToDouble(ObjectGetString(0,"point3",OBJPROP_TEXT,0));
     datetime point1_time=ObjectGetInteger(0,"point1t",OBJPROP_TIME,0);
     datetime deal_time=StringToTime(ObjectGetString(0,"deal_time",OBJPROP_TEXT,0));
     double nowp=SymbolInfoDouble(_Symbol,SYMBOL_BID);
     double vol=PositionGetDouble(POSITION_VOLUME);
     double profit=PositionGetDouble(POSITION_PROFIT);
     double sl=PositionGetDouble(POSITION_SL);
     double deal_price=PositionGetDouble(POSITION_PRICE_OPEN);
     string deal_price_;
     double kuan;
     double SL;
     double escapeS;
     string escapeS_;
     int i,dis;
     double div,breakP1,breakP3,breakP4,breakP11;
     double escape1,escape2;
     string escape1_,escape2_;
     datetime point2_time,escape2_time;
     datetime estime;
     int period;
     double zig1,zig2;
     datetime time1,time2,time3,time_po;
     string time1_,time2_;
     int escape1_pos;
     int flag_escape1_3=0;
     datetime timeS_2;
     double escape1_2,escape2_2;
     string escape1_2_,escape2_2_,timeS_2_;
     datetime time_ag;
     string time_ag_;
     datetime timeS_2to3;
     double escape1_2to3,escape2_2to3;
     string timeS_2to3_,escape1_2to3_,escape2_2to3_;
     double price_ag;
     string price_ag_;
     int position_num=PositionsTotal();
     ulong position_ticket;
     int position_i=position_num;
     int position_sell_num=0;
     while(position_i>0)
     {
        position_ticket=PositionGetTicket(position_i-1);//这是仓位的ticket
        positioninfo.SelectByTicket(position_ticket);
        if((positioninfo.Symbol()==_Symbol)&&(positioninfo.PositionType()==POSITION_TYPE_BUY))
        {
            position_sell_num++;
        }
        position_i--;
     }
     int flag_vol=0;
     if((position_sell_num>1)||(vol==vol_full))
     {
         flag_vol=1;
     }
     if((position_sell_num==1)&&(vol==vol_full/2))
     {
         flag_vol=2;
     }
     if((flag_vol==1)&&(ObjectGetString(0,"escape_ag",OBJPROP_TEXT,0)=="0"))//赚了15个点
     {
        if(ObjectGetString(0,"deal_price",OBJPROP_TEXT,0)=="0")
        {
           deal_price_=DoubleToString(deal_price,8);
           ObjectSetString(0,"deal_price",OBJPROP_TEXT,deal_price_);
        }
        if(ObjectGetString(0,"escape_mode",OBJPROP_TEXT,0)=="0")
        {
           if(profit>=vol_full*150)
           {
              ObjectSetString(0,"escape_mode",OBJPROP_TEXT,"1");
           }
        }
        if(ObjectGetString(0,"escape_mode",OBJPROP_TEXT,0)=="1")
        {
           if(profit>=vol_full*250)
           {
              ObjectSetString(0,"escape_mode",OBJPROP_TEXT,"2");
           }
        }
     }
     /*if(ObjectGetString(0,"escape_ag",OBJPROP_TEXT,0)!="0")
     {
        deal_price=StringToDouble(ObjectGetString(0,"deal_price",OBJPROP_TEXT,0));
        if((nowp<deal_price-0.30)&&(deal_price!=0))
        {
           ObjectSetString(0,"escape_mode",OBJPROP_TEXT,"2");
        }
     }*/
     if(ObjectGetString(0,"point3",OBJPROP_TEXT,0)!="0")//如果有2点、3点
     {
        for(i=barsnum_M1-1;i>barsnum_M1-50000;i--)
        {
            if((Low_M1[i]<=point3)&&(point3_pos==0))point3_pos=i;
            if((Low_M1[i]<=point1)&&(point1_pos==0))
            {
               point1_pos=i;
               break;
            }
        }
     }
     if(ObjectGetString(0,"escape_ag",OBJPROP_TEXT,0)=="0")//没接过单
     {
        if((ObjectGetString(0,"escape_mode",OBJPROP_TEXT,0)=="0")&&(flag_vol==1))//没赚15点,破1-3或更早的通路出1-S，之后下来在下沿出一半
        {
           if(ObjectGetString(0,"escapeS",OBJPROP_TEXT,0)=="0")
           {
              for(i=0;i<tlines_U;i++)
              {
                  if((LineShow_U[i][1]<point3_pos)&&(Low_M1[LineShow_U[i][1]]<point3))
                  break;
              }
              if(i<tlines_U)dis=LineShow_U[i][0]-LineShow_U[i][1];
              else dis=0;
              if(dis!=0)
              {
                 div=Low_M1[LineShow_U[i][0]]-Low_M1[LineShow_U[i][1]];
                 breakP1=div*(barsnum_M1-1-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                 breakP3=div*(barsnum_M1-3-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                 breakP4=div*(barsnum_M1-4-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                 if(nowp<breakP1-50*d_point)
                 {
                    escape1_pos=iHighest(High_M1,barsnum_M1-point1_pos,barsnum_M1-1);
                    escape1_=DoubleToString(High_M1[escape1_pos],8);
                    ObjectSetString(0,"escapeS",OBJPROP_TEXT,"1");
                    ObjectCreate(0,"escapeSt",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                    ObjectSetString(0,"escape1",OBJPROP_TEXT,escape1_);
                    ObjectCreate(0,"escape1t",OBJ_ARROW_THUMB_UP,0,Time_M1[escape1_pos],High_M1[escape1_pos]);
                    time1_=TimeToString(Time_M5[barsnum_M5-1]);
                    ObjectSetString(0,"estime_po",OBJPROP_TEXT,time1_);
                    return;
                 }
                 if(Low_M1[barsnum_M1-3]<breakP3-5*d_point)
                 {
                    if((nowp<Low_M1[barsnum_M1-2]-5*d_point)&&(Low_M1[barsnum_M1-2]<Low_M1[barsnum_M1-3])&&(Low_M1[barsnum_M1-4]>=breakP4))
                    {
                       escape1_pos=iHighest(High_M1,barsnum_M1-point1_pos,barsnum_M1-1);
                       escape1_=DoubleToString(High_M1[escape1_pos],8);
                       ObjectSetString(0,"escapeS",OBJPROP_TEXT,"1");
                       ObjectCreate(0,"escapeSt",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                       ObjectSetString(0,"escape1",OBJPROP_TEXT,escape1_);
                       ObjectCreate(0,"escape1t",OBJ_ARROW_THUMB_UP,0,Time_M1[escape1_pos],High_M1[escape1_pos]);
                       time1_=TimeToString(Time_M5[barsnum_M5-1]);
                       ObjectSetString(0,"estime_po",OBJPROP_TEXT,time1_);
                       return;
                    }
                 }
              }
           }
           else
           {
               escape1=StringToDouble(ObjectGetString(0,"escape1",OBJPROP_TEXT,0));
               time1=StringToTime(ObjectGetString(0,"estime_po",OBJPROP_TEXT,0));
               if(nowp>escape1)
               {
                  ObjectDelete(0,"escapeS");
                  ObjectDelete(0,"escapeSt");
                  ObjectDelete(0,"escape1");
                  ObjectDelete(0,"escape1t");
                  ObjectDelete(0,"estime_po");
                  return;
               }
               for(i=0;i<tlines_D;i++)
               {
                   if((Time_M1[LineShow_D[i][1]]<time1)&&(High_M1[LineShow_D[i][1]]>escape1-(escape1-nowp)/3))
                   {
                      flag_escape1_3=1;
                      break;
                   }
               }
               if(flag_escape1_3==1)
               {
                  dis=LineShow_D[i][0]-LineShow_D[i][1];
                  if(dis!=0)
                  {
                     div=High_M1[LineShow_D[i][0]]-High_M1[LineShow_D[i][1]];
                     breakP1=div*(barsnum_M1-1-LineShow_D[i][0])/dis+High_M1[LineShow_D[i][0]];
                     kuan=div*(LineShow_D[i][2]-LineShow_D[i][0])/dis+High_M1[LineShow_D[i][0]]-Low_M1[LineShow_D[i][2]];
                     if(nowp>breakP1-kuan/10)
                     {
                        fsell(0,vol_full/2);
                        closeby_buy();
                        Alert("没赚15点出一半");
                        ObjectDelete(0,"escapeS");
                        ObjectDelete(0,"escapeSt");
                        ObjectDelete(0,"escape1");
                        ObjectDelete(0,"escape1t");
                        ObjectDelete(0,"estime_po");
                        return;
                     }
                  }
               }
           }
        }
        if((ObjectGetString(0,"escape_mode",OBJPROP_TEXT,0)=="1")&&(flag_vol==1))//赚15点，破3-4出一半
        {
            for(i=0;i<tlines_U;i++)
            {
                if((LineShow_U[i][1]<point3_pos)||(Low_M1[LineShow_U[i][1]]<point3+(nowp-point3)/3))
                break;
            }
            if(i<tlines_U)dis=LineShow_U[i][0]-LineShow_U[i][1];
            else dis=0;
            if(dis!=0)
            {
               div=Low_M1[LineShow_U[i][0]]-Low_M1[LineShow_U[i][1]];
               breakP1=div*(barsnum_M1-1-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
               breakP3=div*(barsnum_M1-3-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
               breakP4=div*(barsnum_M1-4-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
               if(nowp<breakP1-50*d_point)
               {
                  fsell(0,vol_full/2);
                  closeby_buy();
                  Alert("赚15点，破3-4出一半");
                  return;
               }
               if(Low_M1[barsnum_M1-3]<breakP3-5*d_point)
               {
                  if((nowp<Low_M1[barsnum_M1-2]-5*d_point)&&(Low_M1[barsnum_M1-2]<Low_M1[barsnum_M1-3])&&(Low_M1[barsnum_M1-4]>=breakP4))
                  {
                      fsell(0,vol_full/2);
                      closeby_buy();
                      Alert("赚15点，破3-4出一半");
                      return; 
                  }
               }
           }
        }
        if((flag_vol==1)&&(ObjectGetString(0,"escape_mode",OBJPROP_TEXT,0)=="2"))//25点以上
        {
           if(profit>vol_full*500)
           {
              SL=PositionGetDouble(POSITION_PRICE_OPEN);
              if(sl>SL)trade.PositionModify(_Symbol,SL,0);
           }
           if(ObjectGetString(0,"escapeS",OBJPROP_TEXT,0)!="2")//破通道出1和S
           {
              for(i=0;i<tlines_U-1;i++)
              {
                  dis=LineShow_U[i][0]-LineShow_U[i][1];
                  if(dis!=0)
                  {
                     div=Low_M1[LineShow_U[i][0]]-Low_M1[LineShow_U[i][1]];
                     breakP1=div*(barsnum_M1-1-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                     dis=LineShow_U[i+1][0]-LineShow_U[i+1][1];
                     if(dis!=0)
                     {
                        div=Low_M1[LineShow_U[i+1][0]]-Low_M1[LineShow_U[i+1][1]];
                        breakP11=div*(barsnum_M1-1-LineShow_U[i+1][0])/dis+Low_M1[LineShow_U[i+1][0]];
                        if(breakP1-breakP11>200*d_point)break;
                     }
                     else break;
                  }
              }
              if(i<tlines_U)dis=LineShow_U[i][0]-LineShow_U[i][1];
              else dis=0;
              if(dis!=0)
              {
                 div=Low_M1[LineShow_U[i][0]]-Low_M1[LineShow_U[i][1]];
                 breakP1=div*(barsnum_M1-1-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                 breakP3=div*(barsnum_M1-3-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                 breakP4=div*(barsnum_M1-4-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                 if(nowp<breakP1-50*d_point)
                 {
                    ObjectSetString(0,"escapeS",OBJPROP_TEXT,"2");
                    if(ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]]<ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]])
                    {
                       zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
                       time1=Time_M5[ZigZagBuffer_pos_M5[2]];
                    }
                    else
                    {
                        zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
                        time1=Time_M5[ZigZagBuffer_pos_M5[1]];
                    }
                    escape1_=DoubleToString(zig1,8);
                    ObjectCreate(0,"escapeSt",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                    ObjectSetString(0,"escape1",OBJPROP_TEXT,escape1_);
                    ObjectCreate(0,"escape1t",OBJ_ARROW_THUMB_UP,0,time1,zig1);
                    time1_=TimeToString(Time_M5[barsnum_M5-1]);
                    ObjectSetString(0,"estime_po",OBJPROP_TEXT,time1_);
                    return;
                 }
                 if(Low_M1[barsnum_M1-3]<breakP3-5*d_point)
                 {
                    if((nowp<Low_M1[barsnum_M1-2]-5*d_point)&&(Low_M1[barsnum_M1-2]<Low_M1[barsnum_M1-3])&&(Low_M1[barsnum_M1-4]>=breakP4))
                    {
                       ObjectSetString(0,"escapeS",OBJPROP_TEXT,"2");
                       if(ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]]<ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]])
                       {
                          zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
                          time1=Time_M5[ZigZagBuffer_pos_M5[2]];
                       }
                       else
                       {
                           zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
                           time1=Time_M5[ZigZagBuffer_pos_M5[1]];
                       }
                       escape1_=DoubleToString(zig1,8);
                       ObjectCreate(0,"escapeSt",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                       ObjectSetString(0,"escape1",OBJPROP_TEXT,escape1_);
                       ObjectCreate(0,"escape1t",OBJ_ARROW_THUMB_UP,0,time1,zig1);
                       time1_=TimeToString(Time_M5[barsnum_M5-1]);
                       ObjectSetString(0,"estime_po",OBJPROP_TEXT,time1_);
                       return;
                    }
                 }
              }
           }
           if(ObjectGetString(0,"escapeS",OBJPROP_TEXT,0)=="1")
           {
              ObjectDelete(0,"escapeS");
              ObjectDelete(0,"escapeSt");
              ObjectDelete(0,"estime_po");
              ObjectDelete(0,"escape1");
              ObjectDelete(0,"escape1t");
              ObjectDelete(0,"escape2");
              ObjectDelete(0,"escape2t");
              return;
           }
           if(ObjectGetString(0,"escapeS",OBJPROP_TEXT,0)=="2")
           {
              if(ObjectGetString(0,"escape2",OBJPROP_TEXT,0)=="0")
              {
                 escape1=StringToDouble(ObjectGetString(0,"escape1",OBJPROP_TEXT,0));
                 time1=StringToTime(ObjectGetString(0,"estime_po",OBJPROP_TEXT,0));
                 if(nowp>escape1)
                 {
                    ObjectSetString(0,"escape2",OBJPROP_TEXT,"A");//代表打破1点
                    return;
                 }
                 zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
                 zig2=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
                 time2=Time_M5[ZigZagBuffer_pos_M5[2]];
                 if((zig1>zig2)&&(time2>=time1))
                 {
                    escape2_=DoubleToString(zig2,8);
                    ObjectSetString(0,"escape2",OBJPROP_TEXT,escape2_);
                    ObjectCreate(0,"escape2t",OBJ_ARROW_THUMB_UP,0,time2,zig2);
                    return;
                 }
             }
             else
             {
                 if(ObjectGetString(0,"escape2",OBJPROP_TEXT,0)=="A")//破最小的通道出
                 {
                    if(ObjectGetString(0,"beforeS_2",OBJPROP_TEXT,0)=="0")
                    {
                       i=0;
                       if(i<tlines_U)dis=LineShow_U[i][0]-LineShow_U[i][1];
                       else dis=0;
                       if(dis!=0)
                       {
                          div=Low_M1[LineShow_U[i][0]]-Low_M1[LineShow_U[i][1]];
                          breakP1=div*(barsnum_M1-1-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                          breakP3=div*(barsnum_M1-3-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                          breakP4=div*(barsnum_M1-4-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                          if(nowp<breakP1-50*d_point)
                          {
                             timeS_2_=TimeToString(Time_M5[barsnum_M5-1]);
                             escape1_2=High_M1[iHighest(High_M1,barsnum_M1-LineShow_U[i][1],barsnum_M1-1)];
                             escape1_2_=DoubleToString(escape1_2,8);
                             ObjectSetString(0,"beforeS_2",OBJPROP_TEXT,timeS_2_);
                             ObjectSetString(0,"escape1_2",OBJPROP_TEXT,escape1_2_);
                             ObjectCreate(0,"escapeS_2t",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                             return;
                          }
                          if(Low_M1[barsnum_M1-3]<breakP3-5*d_point)
                          {
                             if((nowp<Low_M1[barsnum_M1-2]-5*d_point)&&(Low_M1[barsnum_M1-2]<Low_M1[barsnum_M1-3])&&(Low_M1[barsnum_M1-4]>=breakP4))
                             {
                                timeS_2_=TimeToString(Time_M5[barsnum_M5-1]);
                                escape1_2=High_M1[iHighest(High_M1,barsnum_M1-LineShow_U[i][1],barsnum_M1-1)];
                                escape1_2_=DoubleToString(escape1_2,8);
                                ObjectSetString(0,"beforeS_2",OBJPROP_TEXT,timeS_2_);
                                ObjectSetString(0,"escape1_2",OBJPROP_TEXT,escape1_2_);
                                ObjectCreate(0,"escapeS_2t",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                                return;
                             }
                          }
                       }
                    }
                    else
                    {
                        escape1_2=StringToDouble(ObjectGetString(0,"escape1_2",OBJPROP_TEXT,0));
                        if(nowp>escape1_2)
                        {
                           ObjectDelete(0,"beforeS_2");
                           ObjectDelete(0,"escape1_2");
                           ObjectDelete(0,"escapeS_2t");
                           ObjectDelete(0,"escape2_2");
                           ObjectDelete(0,"escape2_2t");
                           return;
                        }
                        if(ObjectGetString(0,"escape2_2",OBJPROP_TEXT,0)=="0")
                        {
                           escape2_2_=DoubleToString(nowp,8);
                           ObjectSetString(0,"escape2_2",OBJPROP_TEXT,escape2_2_);
                           ObjectCreate(0,"escape2_2t",OBJ_ARROW_THUMB_UP,0,Time_M5[barsnum_M5-1],nowp);
                           return;
                        }
                        else
                        {
                           escape2_2=StringToDouble(ObjectGetString(0,"escape2_2",OBJPROP_TEXT,0));
                           timeS_2=StringToTime(ObjectGetString(0,"beforeS_2",OBJPROP_TEXT,0));
                           if(Time_M5[barsnum_M5-2]>timeS_2)
                           {
                              if(Low_M5[barsnum_M5-2]<escape2_2)
                              {
                                 escape2_2_=DoubleToString(Low_M5[barsnum_M5-2],8);
                                 ObjectSetString(0,"escape2_2",OBJPROP_TEXT,escape2_2_);
                                 ObjectSetDouble(0,"escape2_2t",OBJPROP_PRICE,Low_M5[barsnum_M5-2]);
                                 ObjectSetInteger(0,"escape2_2t",OBJPROP_TIME,Time_M5[barsnum_M5-2]);
                                 return;
                              }
                              if((Low_M5[barsnum_M5-2]>=escape2_2)&&(nowp<escape2_2))
                              {
                                 fsell(0,vol_full/2);
                                 closeby_buy();
                                 ObjectDelete(0,"escape_mode");
                                 ObjectDelete(0,"escapeS");
                                 ObjectDelete(0,"escapeSt");
                                 ObjectDelete(0,"estime_po");
                                 ObjectDelete(0,"escape1");
                                 ObjectDelete(0,"escape1t");
                                 ObjectDelete(0,"escape2");
                                 ObjectDelete(0,"escape2t");
                                 ObjectDelete(0,"beforeS_2");
                                 ObjectDelete(0,"escape1_2");
                                 ObjectDelete(0,"escapeS_2t");
                                 ObjectDelete(0,"escape2_2");
                                 ObjectDelete(0,"escape2_2t");
                                 Alert("25点以上左侧+123出场");
                                 return;
                              }
                           }
                        }
                    }
                 }
                 else//等下来以后破最小的通道出
                 {
                     escape1=StringToDouble(ObjectGetString(0,"escape1",OBJPROP_TEXT,0));
                     time1=StringToTime(ObjectGetString(0,"estime_po",OBJPROP_TEXT,0));
                     if(nowp>escape1)
                     {
                        ObjectSetString(0,"escape2",OBJPROP_TEXT,"A");//代表打破1点
                        return;
                     }
                     escape2=StringToDouble(ObjectGetString(0,"escape2",OBJPROP_TEXT,0));
                     zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
                     zig2=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
                     time2=Time_M5[ZigZagBuffer_pos_M5[2]];
                     escape2_time=ObjectGetInteger(0,"escape2t",OBJPROP_TIME,0);
                     if((zig1<zig2)&&(time2>=escape2_time))
                     {
                        close_buy();
                        Alert("25点以上，123全出");
                        ObjectsDeleteAll(0,0,OBJ_ARROW_THUMB_UP);
                        ObjectsDeleteAll(0,0,OBJ_LABEL);
                        return;
                     }
                  }
              }
           }
        }
     }
     if((ObjectGetString(0,"escape_ag",OBJPROP_TEXT,0)!="0")&&(flag_vol==1))//接过单,破接单之前的通道123出一半，(或者破外面的通道直接全出)
     {
         price_ag=StringToDouble(ObjectGetString(0,"price_ag",OBJPROP_TEXT,0));
         time_ag=StringToTime(ObjectGetString(0,"escape_ag",OBJPROP_TEXT,0));
         if(ObjectGetString(0,"escape_mode",OBJPROP_TEXT,0)!="2")
         {
            if(nowp-price_ag>=250*d_point)ObjectSetString(0,"escape_mode",OBJPROP_TEXT,"2");
            else ObjectSetString(0,"escape_mode",OBJPROP_TEXT,"1");
         }
         if(ObjectGetString(0,"escape_mode",OBJPROP_TEXT,0)=="0")
         {
            i=0;
            if(i<tlines_U)dis=LineShow_U[i][0]-LineShow_U[i][1];
            else dis=0;
            if(dis!=0)
            {
               div=Low_M1[LineShow_U[i][0]]-Low_M1[LineShow_U[i][1]];
               breakP1=div*(barsnum_M1-1-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
               breakP3=div*(barsnum_M1-3-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
               breakP4=div*(barsnum_M1-4-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
               if(nowp<breakP1-70*d_point)
               {
                  fsell(0,vol_full/2);
                  closeby_buy();
                  Alert("接单后亏损，破最小通路出一半");
                  return;
               }
               if(Low_M1[barsnum_M1-3]<breakP3-5*d_point)
               {
                  if((nowp<Low_M1[barsnum_M1-2]-5*d_point)&&(Low_M1[barsnum_M1-2]<Low_M1[barsnum_M1-3])&&(Low_M1[barsnum_M1-4]>=breakP4))
                  {
                     fsell(0,vol_full/2);
                     closeby_buy();
                     Alert("接单后亏损，破最小通路出一半");
                     return; 
                  }
               }
            }
         }
         if(ObjectGetString(0,"escape_mode",OBJPROP_TEXT,0)=="1")
         {
            for(i=0;i<tlines_U;i++)
            {
                if((LineShow_U[i][1]<point3_pos)||(Low_M1[LineShow_U[i][1]]<point3+(nowp-point3)/3))
                break;
            }
            if(i<tlines_U)dis=LineShow_U[i][0]-LineShow_U[i][1];
            else dis=0;
            if(dis!=0)
            {
               div=Low_M1[LineShow_U[i][0]]-Low_M1[LineShow_U[i][1]];
               breakP1=div*(barsnum_M1-1-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
               breakP3=div*(barsnum_M1-3-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
               breakP4=div*(barsnum_M1-4-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
               if(nowp<breakP1-50*d_point)
               {
                  fsell(0,vol_full/2);
                  closeby_buy();
                  Alert("接单后，破3-4出一半");
                  return;
               }
               if(Low_M1[barsnum_M1-3]<breakP3-5*d_point)
               {
                  if((nowp<Low_M1[barsnum_M1-2]-5*d_point)&&(Low_M1[barsnum_M1-2]<Low_M1[barsnum_M1-3])&&(Low_M1[barsnum_M1-4]>=breakP4))
                  {
                     fsell(0,vol_full/2);
                     closeby_buy();
                     Alert("接单后，破3-4出一半");
                     return; 
                  }
               }
            }
         }
         if(ObjectGetString(0,"escape_mode",OBJPROP_TEXT,0)=="2")
         {
            if(ObjectGetString(0,"escape",OBJPROP_TEXT,0)=="0")
            {
               time_ag=StringToTime(ObjectGetString(0,"escape_ag",OBJPROP_TEXT,0));
               for(i=0;i<tlines_U;i++)
               {
                   if(Time_M1[LineShow_U[i][1]]<time_ag)break;
               }
               if((middle_TL>0)&&(middle_TL-1<i))i=middle_TL-1;
               if(i<tlines_U)dis=LineShow_U[i][0]-LineShow_U[i][1];
               else dis=0;
               if(dis!=0)
               {
                  div=Low_M1[LineShow_U[i][0]]-Low_M1[LineShow_U[i][1]];
                  breakP1=div*(barsnum_M1-1-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                  breakP3=div*(barsnum_M1-3-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                  breakP4=div*(barsnum_M1-4-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                  if(nowp<breakP1-50*d_point)
                  {
                     ObjectSetString(0,"escape",OBJPROP_TEXT,"1");
                     if(i==middle_TL-1)
                        ObjectSetString(0,"escape",OBJPROP_TEXT,"2");
                     escapeS_=DoubleToString(breakP1,8);
                     ObjectSetString(0,"escapeS",OBJPROP_TEXT,escapeS_);
                     if(ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]]<ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]])
                     {
                        zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
                        time1=Time_M5[ZigZagBuffer_pos_M5[2]];
                     }
                     else
                     {
                         zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
                         time1=Time_M5[ZigZagBuffer_pos_M5[1]];
                     }
                     escape1_=DoubleToString(zig1,8);
                     ObjectCreate(0,"escapeSt",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                     ObjectSetString(0,"escape1",OBJPROP_TEXT,escape1_);
                     ObjectCreate(0,"escape1t",OBJ_ARROW_THUMB_UP,0,time1,zig1);
                     time1_=TimeToString(Time_M5[barsnum_M5-1]);
                     ObjectSetString(0,"estime_po",OBJPROP_TEXT,time1_);
                     return;
                  }
                  if(Low_M1[barsnum_M1-3]<breakP3-5*d_point)
                  {
                     if((nowp<Low_M1[barsnum_M1-2]-5*d_point)&&(Low_M1[barsnum_M1-2]<Low_M1[barsnum_M1-3])&&(Low_M1[barsnum_M1-4]>=breakP4))
                     {
                        ObjectSetString(0,"escape",OBJPROP_TEXT,"1");
                        if(i==middle_TL-1)
                           ObjectSetString(0,"escape",OBJPROP_TEXT,"2");
                        escapeS_=DoubleToString(breakP1,8);
                        ObjectSetString(0,"escapeS",OBJPROP_TEXT,escapeS_);
                        if(ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]]<ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]])
                        {
                           zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
                           time1=Time_M5[ZigZagBuffer_pos_M5[2]];
                        }
                        else
                        {
                            zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
                            time1=Time_M5[ZigZagBuffer_pos_M5[1]];
                        }
                        escape1_=DoubleToString(zig1,8);
                        ObjectCreate(0,"escapeSt",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                        ObjectSetString(0,"escape1",OBJPROP_TEXT,escape1_);
                        ObjectCreate(0,"escape1t",OBJ_ARROW_THUMB_UP,0,time1,zig1);
                        time1_=TimeToString(Time_M5[barsnum_M5-1]);
                        ObjectSetString(0,"estime_po",OBJPROP_TEXT,time1_);
                        return;
                    }
                  }
               }
            }
            else
            {
                escapeS=StringToDouble(ObjectGetString(0,"escapeS",OBJPROP_TEXT,0));
                escape1=StringToDouble(ObjectGetString(0,"escape1",OBJPROP_TEXT,0));
                estime=StringToTime(ObjectGetString(0,"estime_po",OBJPROP_TEXT,0));
                if(nowp>escape1)
                {
                   ObjectDelete(0,"escape");
                   ObjectDelete(0,"escapeS");
                   ObjectDelete(0,"escapeSt");
                   ObjectDelete(0,"estime_po");
                   ObjectDelete(0,"escape1");
                   ObjectDelete(0,"escape1t");
                   ObjectDelete(0,"escape2");
                   ObjectDelete(0,"escape2t");
                   ObjectDelete(0,"escapeS_2to3");
                   ObjectDelete(0,"escape1_2to3");
                   ObjectDelete(0,"escapeS_2to3t");
                   ObjectDelete(0,"escape2_2to3");
                   ObjectDelete(0,"escape2_2to3t");
                   return;
                }
                if(ObjectGetString(0,"escape2",OBJPROP_TEXT,0)=="0")
                {
                   zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
                   zig2=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
                   time2=Time_M5[ZigZagBuffer_pos_M5[2]];
                   if((zig1>zig2)&&(time2>=estime))
                   {
                     point2_=DoubleToString(zig2,8);
                     ObjectSetString(0,"escape2",OBJPROP_TEXT,point2_);
                     ObjectCreate(0,"escape2t",OBJ_ARROW_THUMB_UP,0,time2,zig2);
                     return;
                   }
                }
                else
                {
                    if(ObjectGetString(0,"escape",OBJPROP_TEXT,0)=="1")vol_now=vol_full/2;
                    if(ObjectGetString(0,"escape",OBJPROP_TEXT,0)=="2")vol_now=vol_full;
                    escape2=StringToDouble(ObjectGetString(0,"escape2",OBJPROP_TEXT,0));
                    zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
                    zig2=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
                    time3=Time_M5[ZigZagBuffer_pos_M5[2]+2];
                    int flag_2to3=0;
                    for(i=0;i<tlines_U;i++)
                    {
                        if((Time_M1[LineShow_U[i][1]]>estime)&&(Low_M1[LineShow_U[i][1]]<escape2+(nowp-escape2)/3))
                        {
                           flag_2to3=1; 
                           break;
                        }
                    }
                    if(ObjectGetString(0,"escapeS_2to3",OBJPROP_TEXT,0)=="0")
                    {
                       if((flag_2to3==1)&&(i<tlines_U))
                       {
                          dis=LineShow_U[i][0]-LineShow_U[i][1];
                          if(dis!=0)
                          {
                             div=Low_M1[LineShow_U[i][0]]-Low_M1[LineShow_U[i][1]];
                             breakP1=div*(barsnum_M1-1-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                             breakP3=div*(barsnum_M1-3-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                             breakP4=div*(barsnum_M1-4-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                          }
                          if(nowp<breakP1-50*d_point)
                          {
                             timeS_2to3_=TimeToString(Time_M5[barsnum_M5-1]);
                             escape1_2to3=High_M1[iHighest(High_M1,barsnum_M1-LineShow_U[i][1],barsnum_M1-1)];
                             escape1_2to3_=DoubleToString(escape1_2to3,8);
                             ObjectSetString(0,"escapeS_2to3",OBJPROP_TEXT,timeS_2to3_);
                             ObjectSetString(0,"escape1_2to3",OBJPROP_TEXT,escape1_2to3_);
                             ObjectCreate(0,"escapeS_2to3t",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                             return;
                          }
                          if(Low_M1[barsnum_M1-3]<breakP3-5*d_point)
                          {
                             if((nowp<Low_M1[barsnum_M1-2]-5*d_point)&&(Low_M1[barsnum_M1-2]<Low_M1[barsnum_M1-3])&&(Low_M1[barsnum_M1-4]>=breakP4))
                             {
                                  timeS_2to3_=TimeToString(Time_M5[barsnum_M5-1]);
                                  escape1_2to3=High_M1[iHighest(High_M1,barsnum_M1-LineShow_U[i][1],barsnum_M1-1)];
                                  escape1_2to3_=DoubleToString(escape1_2to3,8);
                                  ObjectSetString(0,"escapeS_2to3",OBJPROP_TEXT,timeS_2to3_);
                                  ObjectSetString(0,"escape1_2to3",OBJPROP_TEXT,escape1_2to3_);
                                  ObjectCreate(0,"escapeS_2to3t",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                                  return;
                              }
                          }
                       }
                    }
                    else
                    {
                        escape1_2to3=StringToDouble(ObjectGetString(0,"escape1_2to3",OBJPROP_TEXT,0));
                        if(nowp>escape1_2to3)
                        {
                           ObjectDelete(0,"escapeS_2to3");
                           ObjectDelete(0,"escape1_2to3");
                           ObjectDelete(0,"escapeS_2to3t");
                           ObjectDelete(0,"escape2_2to3");
                           ObjectDelete(0,"escape2_2to3t");
                           return;
                        }
                        if(ObjectGetString(0,"escape2_2to3",OBJPROP_TEXT,0)=="0")
                        {
                           escape2_2to3_=DoubleToString(nowp,8);
                           ObjectSetString(0,"escape2_2to3",OBJPROP_TEXT,escape2_2to3_);
                           ObjectCreate(0,"escape2_2to3t",OBJ_ARROW_THUMB_UP,0,Time_M5[barsnum_M5-1],nowp);
                           return;
                        }
                       else
                       {
                            escape2_2to3=StringToDouble(ObjectGetString(0,"escape2_2to3",OBJPROP_TEXT,0));
                            timeS_2to3=StringToTime(ObjectGetString(0,"escapeS_2to3",OBJPROP_TEXT,0));
                            if(Time_M5[barsnum_M5-2]>timeS_2to3)
                            {
                               if(Low_M5[barsnum_M5-2]<escape2_2to3)
                               {
                                  escape2_2to3_=DoubleToString(Low_M5[barsnum_M5-2],8);
                                  ObjectSetString(0,"escape2_2to3",OBJPROP_TEXT,escape2_2to3_);
                                  ObjectSetDouble(0,"escape2_2to3t",OBJPROP_PRICE,Low_M5[barsnum_M5-2]);
                                  ObjectSetInteger(0,"escape2_2to3t",OBJPROP_TIME,Time_M5[barsnum_M5-2]);
                                  return;
                               }
                               if((Low_M5[barsnum_M5-2]>=escape2_2to3)&&(nowp<escape2_2to3))
                               {
                                  close_buy();
                                  Alert("接单以后破中通道2次123全出");
                                  ObjectDelete(0,"escape");
                                  ObjectDelete(0,"escapeS");
                                  ObjectDelete(0,"escapeSt");
                                  ObjectDelete(0,"estime_po");
                                  ObjectDelete(0,"escape1");
                                  ObjectDelete(0,"escape1t");
                                  ObjectDelete(0,"escape2");
                                  ObjectDelete(0,"escape2t");
                                  ObjectDelete(0,"escapeS_2to3");
                                  ObjectDelete(0,"escapeS_2to3t");
                                  ObjectDelete(0,"escape2_2to3");
                                  ObjectDelete(0,"escape2_2to3t");
                                  return;
                               }
                            }
                        }
                    }
                    if((zig1<zig2)&&(time3>=estime)&&(nowp<escapeS))
                    {
                       close_buy();
                       Alert("接单以后破通道123全出，Z字线123");
                       ObjectDelete(0,"escape");
                       ObjectDelete(0,"escapeS");
                       ObjectDelete(0,"escapeSt");
                       ObjectDelete(0,"estime_po");
                       ObjectDelete(0,"escape1");
                       ObjectDelete(0,"escape1t");
                       ObjectDelete(0,"escape2");
                       ObjectDelete(0,"escape2t");
                       ObjectDelete(0,"escapeS_2to3");
                       ObjectDelete(0,"escapeS_2to3t");
                       ObjectDelete(0,"escape2_2to3");
                       ObjectDelete(0,"escape2_2to3t");
                       return;
                    }
                }
            }
        }
     }
     if(flag_vol==2)
     {
        i=barsnum_M1-1;
        while((Time_M1[i]>deal_time)&&(Time_M1[i]>Time_D1[barsnum_D1-10]))
        {
              i--;
        }
        int pointh_pos=iHighest(High_M1,barsnum_M1-i,barsnum_M1-5);
        double pointh=High_M1[pointh_pos];
        double pointl;
        if(ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]]<ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]])
           pointl=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
        else pointl=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
        if(nowp>pointh)
        {
           time_ag_=TimeToString(Time_M5[barsnum_M5-1]);
           ObjectSetString(0,"escape_ag",OBJPROP_TEXT,time_ag_);
           price_ag_=DoubleToString(pointl,8);
           ObjectSetString(0,"price_ag",OBJPROP_TEXT,price_ag_);
           fbuy(sl,vol_full/2);
           Alert("接一半");
           ObjectDelete(0,"escape_mode");
           ObjectDelete(0,"escapeS");
           ObjectDelete(0,"escapeSt");
           ObjectDelete(0,"estime_po");
           ObjectDelete(0,"escape1");
           ObjectDelete(0,"escape1t");
           ObjectDelete(0,"escape2");
           ObjectDelete(0,"escape2t");
           return;
        }
        if(ObjectGetString(0,"escape1_2to3",OBJPROP_TEXT,0)!="0")
        {
           escape1_2to3=StringToDouble(ObjectGetString(0,"escape1_2to3",OBJPROP_TEXT,0));
           if(nowp>escape1_2to3)
           {
              time_ag_=TimeToString(Time_M5[barsnum_M5-1]);
              ObjectSetString(0,"escape_ag",OBJPROP_TEXT,time_ag_);
              price_ag_=DoubleToString(pointl,8);
              ObjectSetString(0,"price_ag",OBJPROP_TEXT,price_ag_);
              fbuy(sl,vol_full/2);
              Alert("双123的接单");
              ObjectDelete(0,"escape_mode");
              ObjectDelete(0,"escapeS");
              ObjectDelete(0,"escapeSt");
              ObjectDelete(0,"estime_po");
              ObjectDelete(0,"escape1");
              ObjectDelete(0,"escape1t");
              ObjectDelete(0,"escape2");
              ObjectDelete(0,"escape2t");
              ObjectDelete(0,"escape1_2to3");
              return;
           }
        }
        if(ObjectGetString(0,"escapeS",OBJPROP_TEXT,0)=="0")
        {
           for(i=0;i<tlines_U-1;i++)
           {
               dis=LineShow_U[i][0]-LineShow_U[i][1];
               if(dis!=0)
               {
                  div=Low_M1[LineShow_U[i][0]]-Low_M1[LineShow_U[i][1]];
                  breakP1=div*(barsnum_M1-1-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                  dis=LineShow_U[i+1][0]-LineShow_U[i+1][1];
                  if(dis!=0)
                  {
                     div=Low_M1[LineShow_U[i+1][0]]-Low_M1[LineShow_U[i+1][1]];
                     breakP11=div*(barsnum_M1-1-LineShow_U[i+1][0])/dis+Low_M1[LineShow_U[i+1][0]];
                     if(breakP1-breakP11>200*d_point)break;
                  }
                  else break;
               }
           }
           if(big_TL>0)
           {
              datetime nowtime=SymbolInfoInteger(_Symbol,SYMBOL_TIME);//当前时间
              HistorySelect(Time_H4[barsnum_H4-60],nowtime);
              int order_num=HistoryOrdersTotal();//选择的历史区间内总交易次数
              int ticket=HistoryOrderGetTicket(order_num-1);//这是选择订单的ticket
              datetime last_deal_time=HistoryOrderGetInteger(ticket,ORDER_TIME_DONE);
              if(HistoryOrderGetInteger(ticket,ORDER_TYPE)==ORDER_TYPE_SELL)
              {
                 for(i=0;i<tlines_U;i++)
                 {
                     if(Time_M1[LineShow_U[i][1]]<last_deal_time)break;
                 }
              }
           }
           if(i<tlines_U)dis=LineShow_U[i][0]-LineShow_U[i][1];
           else dis=0;
           if(dis!=0)
           {
              div=Low_M1[LineShow_U[i][0]]-Low_M1[LineShow_U[i][1]];
              breakP1=div*(barsnum_M1-1-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
              breakP3=div*(barsnum_M1-3-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
              breakP4=div*(barsnum_M1-4-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
              if(nowp<breakP1-50*d_point)
              {
                 escapeS_=DoubleToString(breakP1,8);
                 ObjectSetString(0,"escapeS",OBJPROP_TEXT,escapeS_);
                 ObjectCreate(0,"escapeSt",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                 findperiod2();
                 return;
              }
              if(Low_M1[barsnum_M1-3]<breakP3-5*d_point)
              {
                 if((nowp<Low_M1[barsnum_M1-2]-5*d_point)&&(Low_M1[barsnum_M1-2]<Low_M1[barsnum_M1-3])&&(Low_M1[barsnum_M1-4]>=breakP4))
                 {
                    escapeS_=DoubleToString(breakP1,8);
                    ObjectSetString(0,"escapeS",OBJPROP_TEXT,escapeS_);
                    ObjectCreate(0,"escapeSt",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                    findperiod2();
                    return;
                 }
              }
           }
        }
        else
        {
            escapeS=StringToDouble(ObjectGetString(0,"escapeS",OBJPROP_TEXT,0));
            escape1=StringToDouble(ObjectGetString(0,"escape1",OBJPROP_TEXT,0));
            estime=StringToTime(ObjectGetString(0,"estime_po",OBJPROP_TEXT,0));
            period=StringToInteger(ObjectGetString(0,"trade_period",OBJPROP_TEXT,0));
            if((nowp<escapeS-(escape1-escapeS)/3*2)&&(escape1-escapeS>200*d_point)&&(big_TL<0))
            {
               close_buy();
               Alert("2/3出剩下一半");
               ObjectsDeleteAll(0,0,OBJ_ARROW_THUMB_UP);
               ObjectsDeleteAll(0,0,OBJ_LABEL);
               return;
            }
            if(ObjectGetString(0,"escape2",OBJPROP_TEXT,0)=="0")
            {
               if(nowp>escape1)
               {
                  ObjectDelete(0,"escape1");
                  ObjectDelete(0,"escape1t");
                  ObjectDelete(0,"escapeS");
                  ObjectDelete(0,"escapeSt");
                  return;
               }
               if(period==2)
               {
                  zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
                  zig2=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
                  time2=Time_M5[ZigZagBuffer_pos_M5[2]];
               }
               if(period==3)
               {
                  zig1=ZigZagBuffer_M15[ZigZagBuffer_pos_M15[1]];
                  zig2=ZigZagBuffer_M15[ZigZagBuffer_pos_M15[2]];
                  time2=Time_M15[ZigZagBuffer_pos_M15[2]];
               }
               if((zig1>zig2)&&(time2>=estime))
               {
                  point2_=DoubleToString(zig2,8);
                  ObjectSetString(0,"escape2",OBJPROP_TEXT,point2_);
                  ObjectCreate(0,"escape2t",OBJ_ARROW_THUMB_UP,0,time2,zig2);
                  return;
               }
            }
            else
            {
                if(nowp>escape1)
                {
                   ObjectDelete(0,"escape1");
                   ObjectDelete(0,"escape1t");
                   ObjectDelete(0,"escapeS");
                   ObjectDelete(0,"escapeSt");
                   ObjectDelete(0,"escape2");
                   ObjectDelete(0,"escape2t");
                   return;
                }
                escape2=StringToDouble(ObjectGetString(0,"escape2",OBJPROP_TEXT,0));
                zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
                zig2=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
                time3=Time_M5[ZigZagBuffer_pos_M5[2]+2];
                int flag_2to3=0;
                for(i=0;i<tlines_U;i++)
                {
                    if((Time_M1[LineShow_U[i][1]]>estime)&&(Low_M1[LineShow_U[i][1]]<escape2+(nowp-escape2)/3))
                    {
                       flag_2to3=1; 
                       break;
                    }
                }
                if((flag_2to3==1)&&(i<tlines_D))
                {
                   dis=LineShow_U[i][0]-LineShow_U[i][1];
                   if(dis!=0)
                   {
                      div=Low_M1[LineShow_U[i][0]]-Low_M1[LineShow_U[i][1]];
                      breakP1=div*(barsnum_M1-1-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                      breakP3=div*(barsnum_M1-3-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                      breakP4=div*(barsnum_M1-4-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                      if(nowp<breakP1-50*d_point)
                      {
                         close_buy();
                         Alert("123出剩下一半");
                         ObjectsDeleteAll(0,0,OBJ_ARROW_THUMB_UP);
                         ObjectsDeleteAll(0,0,OBJ_LABEL);
                         return;
                      }
                      if(Low_M1[barsnum_M1-3]<breakP3-5*d_point)
                      {
                         if((nowp<Low_M1[barsnum_M1-2]-5*d_point)&&(Low_M1[barsnum_M1-2]<Low_M1[barsnum_M1-3])&&(Low_M1[barsnum_M1-4]>=breakP4))
                         {
                              close_buy();
                              Alert("123出剩下一半");
                              ObjectsDeleteAll(0,0,OBJ_ARROW_THUMB_UP);
                              ObjectsDeleteAll(0,0,OBJ_LABEL);
                              return;
                          }
                      }
                   }
                }
                if((zig1<zig2)&&(time3>=estime)&&(nowp<escapeS))
                {
                   close_buy();
                   Alert("123出剩下一半");
                   ObjectsDeleteAll(0,0,OBJ_ARROW_THUMB_UP);
                   ObjectsDeleteAll(0,0,OBJ_LABEL);
                   return;
                }
            }
        }
     }
}

void escapeA2()
{
     double vol_full=0.38;
     if(yuanyou==true)vol_full=3.8;
     double point1,point2,point3;
     string point1_,point2_,point3_;
     datetime point1_po;
     string point1_po_;
     int point1_pos=0,point3_pos=0;
     string point1_pos_,point3_pos_;
     point1=StringToDouble(ObjectGetString(0,"point1",OBJPROP_TEXT,0));
     point2=StringToDouble(ObjectGetString(0,"point2",OBJPROP_TEXT,0));
     point3=StringToDouble(ObjectGetString(0,"point3",OBJPROP_TEXT,0));
     datetime point1_time=ObjectGetInteger(0,"point1t",OBJPROP_TIME,0);
     datetime deal_time=StringToTime(ObjectGetString(0,"deal_time",OBJPROP_TEXT,0));
     double nowp=SymbolInfoDouble(_Symbol,SYMBOL_BID);
     double vol=PositionGetDouble(POSITION_VOLUME);
     double profit=PositionGetDouble(POSITION_PROFIT);
     double sl=PositionGetDouble(POSITION_SL);
     double deal_price=PositionGetDouble(POSITION_PRICE_OPEN);
     string deal_price_;
     double kuan;
     double SL;
     double escapeS;
     string escapeS_;
     int i,dis;
     double div,breakP1,breakP3,breakP4,breakP11;
     double escape1,escape2;
     string escape1_,escape2_;
     datetime point2_time,escape2_time;
     datetime estime;
     int period;
     double zig1,zig2;
     datetime time1,time2,time3,time_po;
     string time1_,time2_;
     int escape1_pos;
     int flag_escape1_3=0;
     datetime timeS_2;
     double escape1_2,escape2_2;
     string escape1_2_,escape2_2_,timeS_2_;
     datetime time_ag;
     string time_ag_;
     datetime timeS_2to3;
     double escape1_2to3,escape2_2to3;
     string timeS_2to3_,escape1_2to3_,escape2_2to3_;
     double price_ag;
     string price_ag_;
     int position_num=PositionsTotal();
     ulong position_ticket;
     int position_i=position_num;
     int position_sell_num=0;
     while(position_i>0)
     {
        position_ticket=PositionGetTicket(position_i-1);//这是仓位的ticket
        positioninfo.SelectByTicket(position_ticket);
        if((positioninfo.Symbol()==_Symbol)&&(positioninfo.PositionType()==POSITION_TYPE_BUY))
        {
            position_sell_num++;
        }
        position_i--;
     }
     int flag_vol=0;
     if((position_sell_num>1)||(vol==vol_full))
     {
         flag_vol=1;
     }
     if((position_sell_num==1)&&(vol==vol_full/2))
     {
         flag_vol=2;
     }
     if((flag_vol==1)&&(ObjectGetString(0,"escape_ag",OBJPROP_TEXT,0)=="0"))//赚了15个点
     {
        if(ObjectGetString(0,"deal_price",OBJPROP_TEXT,0)=="0")
        {
           deal_price_=DoubleToString(deal_price,8);
           ObjectSetString(0,"deal_price",OBJPROP_TEXT,deal_price_);
        }
        if(ObjectGetString(0,"escape_mode",OBJPROP_TEXT,0)=="0")
        {
           if(profit>=vol_full*150)
           {
              ObjectSetString(0,"escape_mode",OBJPROP_TEXT,"1");
           }
        }
        if(ObjectGetString(0,"escape_mode",OBJPROP_TEXT,0)=="1")
        {
           if(profit>=vol_full*250)
           {
              ObjectSetString(0,"escape_mode",OBJPROP_TEXT,"2");
           }
        }
     }
     /*if(ObjectGetString(0,"escape_ag",OBJPROP_TEXT,0)!="0")
     {
        deal_price=StringToDouble(ObjectGetString(0,"deal_price",OBJPROP_TEXT,0));
        if((nowp<deal_price-0.30)&&(deal_price!=0))
        {
           ObjectSetString(0,"escape_mode",OBJPROP_TEXT,"2");
        }
     }*/
     if(ObjectGetString(0,"point3",OBJPROP_TEXT,0)!="0")//如果有2点、3点
     {
        for(i=barsnum_M1-1;i>barsnum_M1-50000;i--)
        {
            if((Low_M1[i]<=point3)&&(point3_pos==0))point3_pos=i;
            if((Low_M1[i]<=point1)&&(point1_pos==0))
            {
               point1_pos=i;
               break;
            }
        }
     }
     if(ObjectGetString(0,"escape_ag",OBJPROP_TEXT,0)=="0")//没接过单
     {
        if((ObjectGetString(0,"escape_mode",OBJPROP_TEXT,0)=="0")&&(flag_vol==1))//没赚15点,破1-3或更早的通路出1-S，之后下来在下沿出一半
        {
           if(ObjectGetString(0,"escapeS",OBJPROP_TEXT,0)=="0")
           {
              for(i=0;i<tlines_U;i++)
              {
                  if((LineShow_U[i][1]<point3_pos)&&(Low_M1[LineShow_U[i][1]]<point3))
                  break;
              }
              if(i<tlines_U)dis=LineShow_U[i][0]-LineShow_U[i][1];
              else dis=0;
              if(dis!=0)
              {
                 div=Low_M1[LineShow_U[i][0]]-Low_M1[LineShow_U[i][1]];
                 breakP1=div*(barsnum_M1-1-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                 breakP3=div*(barsnum_M1-3-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                 breakP4=div*(barsnum_M1-4-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                 if(nowp<breakP1-50*d_point)
                 {
                    escape1_pos=iHighest(High_M1,barsnum_M1-point1_pos,barsnum_M1-1);
                    escape1_=DoubleToString(High_M1[escape1_pos],8);
                    ObjectSetString(0,"escapeS",OBJPROP_TEXT,"1");
                    ObjectCreate(0,"escapeSt",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                    ObjectSetString(0,"escape1",OBJPROP_TEXT,escape1_);
                    ObjectCreate(0,"escape1t",OBJ_ARROW_THUMB_UP,0,Time_M1[escape1_pos],High_M1[escape1_pos]);
                    time1_=TimeToString(Time_M5[barsnum_M5-1]);
                    ObjectSetString(0,"estime_po",OBJPROP_TEXT,time1_);
                    return;
                 }
                 if(Low_M1[barsnum_M1-3]<breakP3-5*d_point)
                 {
                    if((nowp<Low_M1[barsnum_M1-2]-5*d_point)&&(Low_M1[barsnum_M1-2]<Low_M1[barsnum_M1-3])&&(Low_M1[barsnum_M1-4]>=breakP4))
                    {
                       escape1_pos=iHighest(High_M1,barsnum_M1-point1_pos,barsnum_M1-1);
                       escape1_=DoubleToString(High_M1[escape1_pos],8);
                       ObjectSetString(0,"escapeS",OBJPROP_TEXT,"1");
                       ObjectCreate(0,"escapeSt",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                       ObjectSetString(0,"escape1",OBJPROP_TEXT,escape1_);
                       ObjectCreate(0,"escape1t",OBJ_ARROW_THUMB_UP,0,Time_M1[escape1_pos],High_M1[escape1_pos]);
                       time1_=TimeToString(Time_M5[barsnum_M5-1]);
                       ObjectSetString(0,"estime_po",OBJPROP_TEXT,time1_);
                       return;
                    }
                 }
              }
           }
           else
           {
               escape1=StringToDouble(ObjectGetString(0,"escape1",OBJPROP_TEXT,0));
               time1=StringToTime(ObjectGetString(0,"estime_po",OBJPROP_TEXT,0));
               if(nowp>escape1)
               {
                  ObjectDelete(0,"escapeS");
                  ObjectDelete(0,"escapeSt");
                  ObjectDelete(0,"escape1");
                  ObjectDelete(0,"escape1t");
                  ObjectDelete(0,"estime_po");
                  return;
               }
               for(i=0;i<tlines_D;i++)
               {
                   if((Time_M1[LineShow_D[i][1]]<time1)&&(High_M1[LineShow_D[i][1]]>escape1-(escape1-nowp)/3))
                   {
                      flag_escape1_3=1;
                      break;
                   }
               }
               if(flag_escape1_3==1)
               {
                  dis=LineShow_D[i][0]-LineShow_D[i][1];
                  if(dis!=0)
                  {
                     div=High_M1[LineShow_D[i][0]]-High_M1[LineShow_D[i][1]];
                     breakP1=div*(barsnum_M1-1-LineShow_D[i][0])/dis+High_M1[LineShow_D[i][0]];
                     kuan=div*(LineShow_D[i][2]-LineShow_D[i][0])/dis+High_M1[LineShow_D[i][0]]-Low_M1[LineShow_D[i][2]];
                     if(nowp>breakP1-kuan/10)
                     {
                        fsell(0,vol_full/2);
                        closeby_buy();
                        Alert("没赚15点出一半");
                        ObjectDelete(0,"escapeS");
                        ObjectDelete(0,"escapeSt");
                        ObjectDelete(0,"escape1");
                        ObjectDelete(0,"escape1t");
                        ObjectDelete(0,"estime_po");
                        return;
                     }
                  }
               }
           }
        }
        if((ObjectGetString(0,"escape_mode",OBJPROP_TEXT,0)=="1")&&(flag_vol==1))//赚15点，破3-4出一半
        {
            for(i=0;i<tlines_U;i++)
            {
                if((LineShow_U[i][1]<point3_pos)||(Low_M1[LineShow_U[i][1]]<point3+(nowp-point3)/3))
                break;
            }
            if(i<tlines_U)dis=LineShow_U[i][0]-LineShow_U[i][1];
            else dis=0;
            if(dis!=0)
            {
               div=Low_M1[LineShow_U[i][0]]-Low_M1[LineShow_U[i][1]];
               breakP1=div*(barsnum_M1-1-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
               breakP3=div*(barsnum_M1-3-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
               breakP4=div*(barsnum_M1-4-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
               if(nowp<breakP1-50*d_point)
               {
                  fsell(0,vol_full/2);
                  closeby_buy();
                  Alert("赚15点，破3-4出一半");
                  return;
               }
               if(Low_M1[barsnum_M1-3]<breakP3-5*d_point)
               {
                  if((nowp<Low_M1[barsnum_M1-2]-5*d_point)&&(Low_M1[barsnum_M1-2]<Low_M1[barsnum_M1-3])&&(Low_M1[barsnum_M1-4]>=breakP4))
                  {
                      fsell(0,vol_full/2);
                      closeby_buy();
                      Alert("赚15点，破3-4出一半");
                      return; 
                  }
               }
           }
        }
        if((flag_vol==1)&&(ObjectGetString(0,"escape_mode",OBJPROP_TEXT,0)=="2"))//25点以上
        {
           if(profit>vol_full*500)
           {
              SL=PositionGetDouble(POSITION_PRICE_OPEN);
              if(sl>SL)trade.PositionModify(_Symbol,SL,0);
           }
           if(ObjectGetString(0,"escapeS",OBJPROP_TEXT,0)!="2")//破通道出1和S
           {
              for(i=0;i<tlines_U-1;i++)
              {
                  dis=LineShow_U[i][0]-LineShow_U[i][1];
                  if(dis!=0)
                  {
                     div=Low_M1[LineShow_U[i][0]]-Low_M1[LineShow_U[i][1]];
                     breakP1=div*(barsnum_M1-1-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                     dis=LineShow_U[i+1][0]-LineShow_U[i+1][1];
                     if(dis!=0)
                     {
                        div=Low_M1[LineShow_U[i+1][0]]-Low_M1[LineShow_U[i+1][1]];
                        breakP11=div*(barsnum_M1-1-LineShow_U[i+1][0])/dis+Low_M1[LineShow_U[i+1][0]];
                        if(breakP1-breakP11>200*d_point)break;
                     }
                     else break;
                  }
              }
              if(i<tlines_U)dis=LineShow_U[i][0]-LineShow_U[i][1];
              else dis=0;
              if(dis!=0)
              {
                 div=Low_M1[LineShow_U[i][0]]-Low_M1[LineShow_U[i][1]];
                 breakP1=div*(barsnum_M1-1-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                 breakP3=div*(barsnum_M1-3-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                 breakP4=div*(barsnum_M1-4-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                 if(nowp<breakP1-50*d_point)
                 {
                    ObjectSetString(0,"escapeS",OBJPROP_TEXT,"2");
                    if(ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]]<ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]])
                    {
                       zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
                       time1=Time_M5[ZigZagBuffer_pos_M5[2]];
                    }
                    else
                    {
                        zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
                        time1=Time_M5[ZigZagBuffer_pos_M5[1]];
                    }
                    escape1_=DoubleToString(zig1,8);
                    ObjectCreate(0,"escapeSt",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                    ObjectSetString(0,"escape1",OBJPROP_TEXT,escape1_);
                    ObjectCreate(0,"escape1t",OBJ_ARROW_THUMB_UP,0,time1,zig1);
                    time1_=TimeToString(Time_M5[barsnum_M5-1]);
                    ObjectSetString(0,"estime_po",OBJPROP_TEXT,time1_);
                    return;
                 }
                 if(Low_M1[barsnum_M1-3]<breakP3-5*d_point)
                 {
                    if((nowp<Low_M1[barsnum_M1-2]-5*d_point)&&(Low_M1[barsnum_M1-2]<Low_M1[barsnum_M1-3])&&(Low_M1[barsnum_M1-4]>=breakP4))
                    {
                       ObjectSetString(0,"escapeS",OBJPROP_TEXT,"2");
                       if(ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]]<ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]])
                       {
                          zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
                          time1=Time_M5[ZigZagBuffer_pos_M5[2]];
                       }
                       else
                       {
                           zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
                           time1=Time_M5[ZigZagBuffer_pos_M5[1]];
                       }
                       escape1_=DoubleToString(zig1,8);
                       ObjectCreate(0,"escapeSt",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                       ObjectSetString(0,"escape1",OBJPROP_TEXT,escape1_);
                       ObjectCreate(0,"escape1t",OBJ_ARROW_THUMB_UP,0,time1,zig1);
                       time1_=TimeToString(Time_M5[barsnum_M5-1]);
                       ObjectSetString(0,"estime_po",OBJPROP_TEXT,time1_);
                       return;
                    }
                 }
              }
           }
           if(ObjectGetString(0,"escapeS",OBJPROP_TEXT,0)=="1")
           {
              ObjectDelete(0,"escapeS");
              ObjectDelete(0,"escapeSt");
              ObjectDelete(0,"estime_po");
              ObjectDelete(0,"escape1");
              ObjectDelete(0,"escape1t");
              ObjectDelete(0,"escape2");
              ObjectDelete(0,"escape2t");
              return;
           }
           if(ObjectGetString(0,"escapeS",OBJPROP_TEXT,0)=="2")
           {
              if(ObjectGetString(0,"escape2",OBJPROP_TEXT,0)=="0")
              {
                 escape1=StringToDouble(ObjectGetString(0,"escape1",OBJPROP_TEXT,0));
                 time1=StringToTime(ObjectGetString(0,"estime_po",OBJPROP_TEXT,0));
                 if(nowp>escape1)
                 {
                    ObjectSetString(0,"escape2",OBJPROP_TEXT,"A");//代表打破1点
                    return;
                 }
                 zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
                 zig2=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
                 time2=Time_M5[ZigZagBuffer_pos_M5[2]];
                 if((zig1>zig2)&&(time2>=time1))
                 {
                    escape2_=DoubleToString(zig2,8);
                    ObjectSetString(0,"escape2",OBJPROP_TEXT,escape2_);
                    ObjectCreate(0,"escape2t",OBJ_ARROW_THUMB_UP,0,time2,zig2);
                    return;
                 }
             }
             else
             {
                 if(ObjectGetString(0,"escape2",OBJPROP_TEXT,0)=="A")//破最小的通道出
                 {
                    if(ObjectGetString(0,"beforeS_2",OBJPROP_TEXT,0)=="0")
                    {
                       i=0;
                       if(i<tlines_U)dis=LineShow_U[i][0]-LineShow_U[i][1];
                       else dis=0;
                       if(dis!=0)
                       {
                          div=Low_M1[LineShow_U[i][0]]-Low_M1[LineShow_U[i][1]];
                          breakP1=div*(barsnum_M1-1-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                          breakP3=div*(barsnum_M1-3-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                          breakP4=div*(barsnum_M1-4-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                          if(nowp<breakP1-50*d_point)
                          {
                             timeS_2_=TimeToString(Time_M5[barsnum_M5-1]);
                             escape1_2=High_M1[iHighest(High_M1,barsnum_M1-LineShow_U[i][1],barsnum_M1-1)];
                             escape1_2_=DoubleToString(escape1_2,8);
                             ObjectSetString(0,"beforeS_2",OBJPROP_TEXT,timeS_2_);
                             ObjectSetString(0,"escape1_2",OBJPROP_TEXT,escape1_2_);
                             ObjectCreate(0,"escapeS_2t",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                             return;
                          }
                          if(Low_M1[barsnum_M1-3]<breakP3-5*d_point)
                          {
                             if((nowp<Low_M1[barsnum_M1-2]-5*d_point)&&(Low_M1[barsnum_M1-2]<Low_M1[barsnum_M1-3])&&(Low_M1[barsnum_M1-4]>=breakP4))
                             {
                                timeS_2_=TimeToString(Time_M5[barsnum_M5-1]);
                                escape1_2=High_M1[iHighest(High_M1,barsnum_M1-LineShow_U[i][1],barsnum_M1-1)];
                                escape1_2_=DoubleToString(escape1_2,8);
                                ObjectSetString(0,"beforeS_2",OBJPROP_TEXT,timeS_2_);
                                ObjectSetString(0,"escape1_2",OBJPROP_TEXT,escape1_2_);
                                ObjectCreate(0,"escapeS_2t",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                                return;
                             }
                          }
                       }
                    }
                    else
                    {
                        escape1_2=StringToDouble(ObjectGetString(0,"escape1_2",OBJPROP_TEXT,0));
                        if(nowp>escape1_2)
                        {
                           ObjectDelete(0,"beforeS_2");
                           ObjectDelete(0,"escape1_2");
                           ObjectDelete(0,"escapeS_2t");
                           ObjectDelete(0,"escape2_2");
                           ObjectDelete(0,"escape2_2t");
                           return;
                        }
                        if(ObjectGetString(0,"escape2_2",OBJPROP_TEXT,0)=="0")
                        {
                           escape2_2_=DoubleToString(nowp,8);
                           ObjectSetString(0,"escape2_2",OBJPROP_TEXT,escape2_2_);
                           ObjectCreate(0,"escape2_2t",OBJ_ARROW_THUMB_UP,0,Time_M5[barsnum_M5-1],nowp);
                           return;
                        }
                        else
                        {
                           escape2_2=StringToDouble(ObjectGetString(0,"escape2_2",OBJPROP_TEXT,0));
                           timeS_2=StringToTime(ObjectGetString(0,"beforeS_2",OBJPROP_TEXT,0));
                           if(Time_M5[barsnum_M5-2]>timeS_2)
                           {
                              if(Low_M5[barsnum_M5-2]<escape2_2)
                              {
                                 escape2_2_=DoubleToString(Low_M5[barsnum_M5-2],8);
                                 ObjectSetString(0,"escape2_2",OBJPROP_TEXT,escape2_2_);
                                 ObjectSetDouble(0,"escape2_2t",OBJPROP_PRICE,Low_M5[barsnum_M5-2]);
                                 ObjectSetInteger(0,"escape2_2t",OBJPROP_TIME,Time_M5[barsnum_M5-2]);
                                 return;
                              }
                              if((Low_M5[barsnum_M5-2]>=escape2_2)&&(nowp<escape2_2))
                              {
                                 fsell(0,vol_full/2);
                                 closeby_buy();
                                 ObjectDelete(0,"escape_mode");
                                 ObjectDelete(0,"escapeS");
                                 ObjectDelete(0,"escapeSt");
                                 ObjectDelete(0,"estime_po");
                                 ObjectDelete(0,"escape1");
                                 ObjectDelete(0,"escape1t");
                                 ObjectDelete(0,"escape2");
                                 ObjectDelete(0,"escape2t");
                                 ObjectDelete(0,"beforeS_2");
                                 ObjectDelete(0,"escape1_2");
                                 ObjectDelete(0,"escapeS_2t");
                                 ObjectDelete(0,"escape2_2");
                                 ObjectDelete(0,"escape2_2t");
                                 Alert("25点以上左侧+123出场");
                                 return;
                              }
                           }
                        }
                    }
                 }
                 else//等下来以后破最小的通道出
                 {
                     escape1=StringToDouble(ObjectGetString(0,"escape1",OBJPROP_TEXT,0));
                     time1=StringToTime(ObjectGetString(0,"estime_po",OBJPROP_TEXT,0));
                     if(nowp>escape1)
                     {
                        ObjectSetString(0,"escape2",OBJPROP_TEXT,"A");//代表打破1点
                        return;
                     }
                     escape2=StringToDouble(ObjectGetString(0,"escape2",OBJPROP_TEXT,0));
                     zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
                     zig2=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
                     time2=Time_M5[ZigZagBuffer_pos_M5[2]];
                     escape2_time=ObjectGetInteger(0,"escape2t",OBJPROP_TIME,0);
                     if((zig1<zig2)&&(time2>=escape2_time))
                     {
                        close_buy();
                        Alert("25点以上，123全出");
                        ObjectsDeleteAll(0,0,OBJ_ARROW_THUMB_UP);
                        ObjectsDeleteAll(0,0,OBJ_LABEL);
                        return;
                     }
                  }
              }
           }
        }
     }
     if((ObjectGetString(0,"escape_ag",OBJPROP_TEXT,0)!="0")&&(flag_vol==1))//接过单,破接单之前的通道123出一半，(或者破外面的通道直接全出)
     {
         price_ag=StringToDouble(ObjectGetString(0,"price_ag",OBJPROP_TEXT,0));
         time_ag=StringToTime(ObjectGetString(0,"escape_ag",OBJPROP_TEXT,0));
         if(ObjectGetString(0,"escape_mode",OBJPROP_TEXT,0)!="2")
         {
            if(nowp-price_ag>=250*d_point)ObjectSetString(0,"escape_mode",OBJPROP_TEXT,"2");
            else ObjectSetString(0,"escape_mode",OBJPROP_TEXT,"1");
         }
         if(ObjectGetString(0,"escape_mode",OBJPROP_TEXT,0)=="0")
         {
            i=0;
            if(i<tlines_U)dis=LineShow_U[i][0]-LineShow_U[i][1];
            else dis=0;
            if(dis!=0)
            {
               div=Low_M1[LineShow_U[i][0]]-Low_M1[LineShow_U[i][1]];
               breakP1=div*(barsnum_M1-1-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
               breakP3=div*(barsnum_M1-3-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
               breakP4=div*(barsnum_M1-4-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
               if(nowp<breakP1-70*d_point)
               {
                  fsell(0,vol_full/2);
                  closeby_buy();
                  Alert("接单后亏损，破最小通路出一半");
                  return;
               }
               if(Low_M1[barsnum_M1-3]<breakP3-5*d_point)
               {
                  if((nowp<Low_M1[barsnum_M1-2]-5*d_point)&&(Low_M1[barsnum_M1-2]<Low_M1[barsnum_M1-3])&&(Low_M1[barsnum_M1-4]>=breakP4))
                  {
                     fsell(0,vol_full/2);
                     closeby_buy();
                     Alert("接单后亏损，破最小通路出一半");
                     return; 
                  }
               }
            }
         }
         if(ObjectGetString(0,"escape_mode",OBJPROP_TEXT,0)=="1")
         {
            for(i=0;i<tlines_U;i++)
            {
                if((LineShow_U[i][1]<point3_pos)||(Low_M1[LineShow_U[i][1]]<point3+(nowp-point3)/3))
                break;
            }
            if(i<tlines_U)dis=LineShow_U[i][0]-LineShow_U[i][1];
            else dis=0;
            if(dis!=0)
            {
               div=Low_M1[LineShow_U[i][0]]-Low_M1[LineShow_U[i][1]];
               breakP1=div*(barsnum_M1-1-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
               breakP3=div*(barsnum_M1-3-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
               breakP4=div*(barsnum_M1-4-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
               if(nowp<breakP1-50*d_point)
               {
                  fsell(0,vol_full/2);
                  closeby_buy();
                  Alert("接单后，破3-4出一半");
                  return;
               }
               if(Low_M1[barsnum_M1-3]<breakP3-5*d_point)
               {
                  if((nowp<Low_M1[barsnum_M1-2]-5*d_point)&&(Low_M1[barsnum_M1-2]<Low_M1[barsnum_M1-3])&&(Low_M1[barsnum_M1-4]>=breakP4))
                  {
                     fsell(0,vol_full/2);
                     closeby_buy();
                     Alert("接单后，破3-4出一半");
                     return; 
                  }
               }
            }
         }
         if(ObjectGetString(0,"escape_mode",OBJPROP_TEXT,0)=="2")
         {
            if(ObjectGetString(0,"escape",OBJPROP_TEXT,0)=="0")
            {
               time_ag=StringToTime(ObjectGetString(0,"escape_ag",OBJPROP_TEXT,0));
               for(i=0;i<tlines_U;i++)
               {
                   if(Time_M1[LineShow_U[i][1]]<time_ag)break;
               }
               if((middle_TL>0)&&(middle_TL-1<i))i=middle_TL-1;
               if(i<tlines_U)dis=LineShow_U[i][0]-LineShow_U[i][1];
               else dis=0;
               if(dis!=0)
               {
                  div=Low_M1[LineShow_U[i][0]]-Low_M1[LineShow_U[i][1]];
                  breakP1=div*(barsnum_M1-1-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                  breakP3=div*(barsnum_M1-3-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                  breakP4=div*(barsnum_M1-4-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                  if(nowp<breakP1-50*d_point)
                  {
                     ObjectSetString(0,"escape",OBJPROP_TEXT,"1");
                     if(i==middle_TL-1)
                        ObjectSetString(0,"escape",OBJPROP_TEXT,"2");
                     escapeS_=DoubleToString(breakP1,8);
                     ObjectSetString(0,"escapeS",OBJPROP_TEXT,escapeS_);
                     if(ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]]<ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]])
                     {
                        zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
                        time1=Time_M5[ZigZagBuffer_pos_M5[2]];
                     }
                     else
                     {
                         zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
                         time1=Time_M5[ZigZagBuffer_pos_M5[1]];
                     }
                     escape1_=DoubleToString(zig1,8);
                     ObjectCreate(0,"escapeSt",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                     ObjectSetString(0,"escape1",OBJPROP_TEXT,escape1_);
                     ObjectCreate(0,"escape1t",OBJ_ARROW_THUMB_UP,0,time1,zig1);
                     time1_=TimeToString(Time_M5[barsnum_M5-1]);
                     ObjectSetString(0,"estime_po",OBJPROP_TEXT,time1_);
                     return;
                  }
                  if(Low_M1[barsnum_M1-3]<breakP3-5*d_point)
                  {
                     if((nowp<Low_M1[barsnum_M1-2]-5*d_point)&&(Low_M1[barsnum_M1-2]<Low_M1[barsnum_M1-3])&&(Low_M1[barsnum_M1-4]>=breakP4))
                     {
                        ObjectSetString(0,"escape",OBJPROP_TEXT,"1");
                        if(i==middle_TL-1)
                           ObjectSetString(0,"escape",OBJPROP_TEXT,"2");
                        escapeS_=DoubleToString(breakP1,8);
                        ObjectSetString(0,"escapeS",OBJPROP_TEXT,escapeS_);
                        if(ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]]<ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]])
                        {
                           zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
                           time1=Time_M5[ZigZagBuffer_pos_M5[2]];
                        }
                        else
                        {
                            zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
                            time1=Time_M5[ZigZagBuffer_pos_M5[1]];
                        }
                        escape1_=DoubleToString(zig1,8);
                        ObjectCreate(0,"escapeSt",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                        ObjectSetString(0,"escape1",OBJPROP_TEXT,escape1_);
                        ObjectCreate(0,"escape1t",OBJ_ARROW_THUMB_UP,0,time1,zig1);
                        time1_=TimeToString(Time_M5[barsnum_M5-1]);
                        ObjectSetString(0,"estime_po",OBJPROP_TEXT,time1_);
                        return;
                    }
                  }
               }
            }
            else
            {
                escapeS=StringToDouble(ObjectGetString(0,"escapeS",OBJPROP_TEXT,0));
                escape1=StringToDouble(ObjectGetString(0,"escape1",OBJPROP_TEXT,0));
                estime=StringToTime(ObjectGetString(0,"estime_po",OBJPROP_TEXT,0));
                if(nowp>escape1)
                {
                   ObjectDelete(0,"escape");
                   ObjectDelete(0,"escapeS");
                   ObjectDelete(0,"escapeSt");
                   ObjectDelete(0,"estime_po");
                   ObjectDelete(0,"escape1");
                   ObjectDelete(0,"escape1t");
                   ObjectDelete(0,"escape2");
                   ObjectDelete(0,"escape2t");
                   ObjectDelete(0,"escapeS_2to3");
                   ObjectDelete(0,"escape1_2to3");
                   ObjectDelete(0,"escapeS_2to3t");
                   ObjectDelete(0,"escape2_2to3");
                   ObjectDelete(0,"escape2_2to3t");
                   return;
                }
                if(ObjectGetString(0,"escape2",OBJPROP_TEXT,0)=="0")
                {
                   zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
                   zig2=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
                   time2=Time_M5[ZigZagBuffer_pos_M5[2]];
                   if((zig1>zig2)&&(time2>=estime))
                   {
                     point2_=DoubleToString(zig2,8);
                     ObjectSetString(0,"escape2",OBJPROP_TEXT,point2_);
                     ObjectCreate(0,"escape2t",OBJ_ARROW_THUMB_UP,0,time2,zig2);
                     return;
                   }
                }
                else
                {
                    if(ObjectGetString(0,"escape",OBJPROP_TEXT,0)=="1")vol_now=vol_full/2;
                    if(ObjectGetString(0,"escape",OBJPROP_TEXT,0)=="2")vol_now=vol_full;
                    escape2=StringToDouble(ObjectGetString(0,"escape2",OBJPROP_TEXT,0));
                    zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
                    zig2=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
                    time3=Time_M5[ZigZagBuffer_pos_M5[2]+2];
                    int flag_2to3=0;
                    for(i=0;i<tlines_U;i++)
                    {
                        if((Time_M1[LineShow_U[i][1]]>estime)&&(Low_M1[LineShow_U[i][1]]<escape2+(nowp-escape2)/3))
                        {
                           flag_2to3=1; 
                           break;
                        }
                    }
                    if(ObjectGetString(0,"escapeS_2to3",OBJPROP_TEXT,0)=="0")
                    {
                       if((flag_2to3==1)&&(i<tlines_U))
                       {
                          dis=LineShow_U[i][0]-LineShow_U[i][1];
                          if(dis!=0)
                          {
                             div=Low_M1[LineShow_U[i][0]]-Low_M1[LineShow_U[i][1]];
                             breakP1=div*(barsnum_M1-1-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                             breakP3=div*(barsnum_M1-3-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                             breakP4=div*(barsnum_M1-4-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                          }
                          if(nowp<breakP1-50*d_point)
                          {
                             timeS_2to3_=TimeToString(Time_M5[barsnum_M5-1]);
                             escape1_2to3=High_M1[iHighest(High_M1,barsnum_M1-LineShow_U[i][1],barsnum_M1-1)];
                             escape1_2to3_=DoubleToString(escape1_2to3,8);
                             ObjectSetString(0,"escapeS_2to3",OBJPROP_TEXT,timeS_2to3_);
                             ObjectSetString(0,"escape1_2to3",OBJPROP_TEXT,escape1_2to3_);
                             ObjectCreate(0,"escapeS_2to3t",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                             return;
                          }
                          if(Low_M1[barsnum_M1-3]<breakP3-5*d_point)
                          {
                             if((nowp<Low_M1[barsnum_M1-2]-5*d_point)&&(Low_M1[barsnum_M1-2]<Low_M1[barsnum_M1-3])&&(Low_M1[barsnum_M1-4]>=breakP4))
                             {
                                  timeS_2to3_=TimeToString(Time_M5[barsnum_M5-1]);
                                  escape1_2to3=High_M1[iHighest(High_M1,barsnum_M1-LineShow_U[i][1],barsnum_M1-1)];
                                  escape1_2to3_=DoubleToString(escape1_2to3,8);
                                  ObjectSetString(0,"escapeS_2to3",OBJPROP_TEXT,timeS_2to3_);
                                  ObjectSetString(0,"escape1_2to3",OBJPROP_TEXT,escape1_2to3_);
                                  ObjectCreate(0,"escapeS_2to3t",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                                  return;
                              }
                          }
                       }
                    }
                    else
                    {
                        escape1_2to3=StringToDouble(ObjectGetString(0,"escape1_2to3",OBJPROP_TEXT,0));
                        if(nowp>escape1_2to3)
                        {
                           ObjectDelete(0,"escapeS_2to3");
                           ObjectDelete(0,"escape1_2to3");
                           ObjectDelete(0,"escapeS_2to3t");
                           ObjectDelete(0,"escape2_2to3");
                           ObjectDelete(0,"escape2_2to3t");
                           return;
                        }
                        if(ObjectGetString(0,"escape2_2to3",OBJPROP_TEXT,0)=="0")
                        {
                           escape2_2to3_=DoubleToString(nowp,8);
                           ObjectSetString(0,"escape2_2to3",OBJPROP_TEXT,escape2_2to3_);
                           ObjectCreate(0,"escape2_2to3t",OBJ_ARROW_THUMB_UP,0,Time_M5[barsnum_M5-1],nowp);
                           return;
                        }
                       else
                       {
                            escape2_2to3=StringToDouble(ObjectGetString(0,"escape2_2to3",OBJPROP_TEXT,0));
                            timeS_2to3=StringToTime(ObjectGetString(0,"escapeS_2to3",OBJPROP_TEXT,0));
                            if(Time_M5[barsnum_M5-2]>timeS_2to3)
                            {
                               if(Low_M5[barsnum_M5-2]<escape2_2to3)
                               {
                                  escape2_2to3_=DoubleToString(Low_M5[barsnum_M5-2],8);
                                  ObjectSetString(0,"escape2_2to3",OBJPROP_TEXT,escape2_2to3_);
                                  ObjectSetDouble(0,"escape2_2to3t",OBJPROP_PRICE,Low_M5[barsnum_M5-2]);
                                  ObjectSetInteger(0,"escape2_2to3t",OBJPROP_TIME,Time_M5[barsnum_M5-2]);
                                  return;
                               }
                               if((Low_M5[barsnum_M5-2]>=escape2_2to3)&&(nowp<escape2_2to3))
                               {
                                  close_buy();
                                  Alert("接单以后破中通道2次123全出");
                                  ObjectDelete(0,"escape");
                                  ObjectDelete(0,"escapeS");
                                  ObjectDelete(0,"escapeSt");
                                  ObjectDelete(0,"estime_po");
                                  ObjectDelete(0,"escape1");
                                  ObjectDelete(0,"escape1t");
                                  ObjectDelete(0,"escape2");
                                  ObjectDelete(0,"escape2t");
                                  ObjectDelete(0,"escapeS_2to3");
                                  ObjectDelete(0,"escapeS_2to3t");
                                  ObjectDelete(0,"escape2_2to3");
                                  ObjectDelete(0,"escape2_2to3t");
                                  return;
                               }
                            }
                        }
                    }
                    if((zig1<zig2)&&(time3>=estime)&&(nowp<escapeS))
                    {
                       close_buy();
                       Alert("接单以后破通道123全出，Z字线123");
                       ObjectDelete(0,"escape");
                       ObjectDelete(0,"escapeS");
                       ObjectDelete(0,"escapeSt");
                       ObjectDelete(0,"estime_po");
                       ObjectDelete(0,"escape1");
                       ObjectDelete(0,"escape1t");
                       ObjectDelete(0,"escape2");
                       ObjectDelete(0,"escape2t");
                       ObjectDelete(0,"escapeS_2to3");
                       ObjectDelete(0,"escapeS_2to3t");
                       ObjectDelete(0,"escape2_2to3");
                       ObjectDelete(0,"escape2_2to3t");
                       return;
                    }
                }
            }
        }
     }
     if(flag_vol==2)
     {
        i=barsnum_M1-1;
        while((Time_M1[i]>deal_time)&&(Time_M1[i]>Time_D1[barsnum_D1-10]))
        {
              i--;
        }
        int pointh_pos=iHighest(High_M1,barsnum_M1-i,barsnum_M1-5);
        double pointh=High_M1[pointh_pos];
        double pointl;
        if(ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]]<ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]])
           pointl=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
        else pointl=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
        if(nowp>pointh)
        {
           time_ag_=TimeToString(Time_M5[barsnum_M5-1]);
           ObjectSetString(0,"escape_ag",OBJPROP_TEXT,time_ag_);
           price_ag_=DoubleToString(pointl,8);
           ObjectSetString(0,"price_ag",OBJPROP_TEXT,price_ag_);
           fbuy(sl,vol_full/2);
           Alert("接一半");
           ObjectDelete(0,"escape_mode");
           ObjectDelete(0,"escapeS");
           ObjectDelete(0,"escapeSt");
           ObjectDelete(0,"estime_po");
           ObjectDelete(0,"escape1");
           ObjectDelete(0,"escape1t");
           ObjectDelete(0,"escape2");
           ObjectDelete(0,"escape2t");
           return;
        }
        if(ObjectGetString(0,"escape1_2to3",OBJPROP_TEXT,0)!="0")
        {
           escape1_2to3=StringToDouble(ObjectGetString(0,"escape1_2to3",OBJPROP_TEXT,0));
           if(nowp>escape1_2to3)
           {
              time_ag_=TimeToString(Time_M5[barsnum_M5-1]);
              ObjectSetString(0,"escape_ag",OBJPROP_TEXT,time_ag_);
              price_ag_=DoubleToString(pointl,8);
              ObjectSetString(0,"price_ag",OBJPROP_TEXT,price_ag_);
              fbuy(sl,vol_full/2);
              Alert("双123的接单");
              ObjectDelete(0,"escape_mode");
              ObjectDelete(0,"escapeS");
              ObjectDelete(0,"escapeSt");
              ObjectDelete(0,"estime_po");
              ObjectDelete(0,"escape1");
              ObjectDelete(0,"escape1t");
              ObjectDelete(0,"escape2");
              ObjectDelete(0,"escape2t");
              ObjectDelete(0,"escape1_2to3");
              return;
           }
        }
        if(ObjectGetString(0,"escapeS",OBJPROP_TEXT,0)=="0")
        {
           for(i=0;i<tlines_U-1;i++)
           {
               dis=LineShow_U[i][0]-LineShow_U[i][1];
               if(dis!=0)
               {
                  div=Low_M1[LineShow_U[i][0]]-Low_M1[LineShow_U[i][1]];
                  breakP1=div*(barsnum_M1-1-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                  dis=LineShow_U[i+1][0]-LineShow_U[i+1][1];
                  if(dis!=0)
                  {
                     div=Low_M1[LineShow_U[i+1][0]]-Low_M1[LineShow_U[i+1][1]];
                     breakP11=div*(barsnum_M1-1-LineShow_U[i+1][0])/dis+Low_M1[LineShow_U[i+1][0]];
                     if(breakP1-breakP11>200*d_point)break;
                  }
                  else break;
               }
           }
           if(big_TL>0)
           {
              datetime nowtime=SymbolInfoInteger(_Symbol,SYMBOL_TIME);//当前时间
              HistorySelect(Time_H4[barsnum_H4-60],nowtime);
              int order_num=HistoryOrdersTotal();//选择的历史区间内总交易次数
              int ticket=HistoryOrderGetTicket(order_num-1);//这是选择订单的ticket
              datetime last_deal_time=HistoryOrderGetInteger(ticket,ORDER_TIME_DONE);
              if(HistoryOrderGetInteger(ticket,ORDER_TYPE)==ORDER_TYPE_SELL)
              {
                 for(i=0;i<tlines_U;i++)
                 {
                     if(Time_M1[LineShow_U[i][1]]<last_deal_time)break;
                 }
              }
           }
           if(i<tlines_U)dis=LineShow_U[i][0]-LineShow_U[i][1];
           else dis=0;
           if(dis!=0)
           {
              div=Low_M1[LineShow_U[i][0]]-Low_M1[LineShow_U[i][1]];
              breakP1=div*(barsnum_M1-1-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
              breakP3=div*(barsnum_M1-3-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
              breakP4=div*(barsnum_M1-4-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
              if(nowp<breakP1-50*d_point)
              {
                 escapeS_=DoubleToString(breakP1,8);
                 ObjectSetString(0,"escapeS",OBJPROP_TEXT,escapeS_);
                 ObjectCreate(0,"escapeSt",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                 findperiod2();
                 return;
              }
              if(Low_M1[barsnum_M1-3]<breakP3-5*d_point)
              {
                 if((nowp<Low_M1[barsnum_M1-2]-5*d_point)&&(Low_M1[barsnum_M1-2]<Low_M1[barsnum_M1-3])&&(Low_M1[barsnum_M1-4]>=breakP4))
                 {
                    escapeS_=DoubleToString(breakP1,8);
                    ObjectSetString(0,"escapeS",OBJPROP_TEXT,escapeS_);
                    ObjectCreate(0,"escapeSt",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                    findperiod2();
                    return;
                 }
              }
           }
        }
        else
        {
            escapeS=StringToDouble(ObjectGetString(0,"escapeS",OBJPROP_TEXT,0));
            escape1=StringToDouble(ObjectGetString(0,"escape1",OBJPROP_TEXT,0));
            estime=StringToTime(ObjectGetString(0,"estime_po",OBJPROP_TEXT,0));
            period=StringToInteger(ObjectGetString(0,"trade_period",OBJPROP_TEXT,0));
            if((nowp<escapeS-(escape1-escapeS)/3*2)&&(escape1-escapeS>200*d_point)&&(big_TL<0))
            {
               close_buy();
               Alert("2/3出剩下一半");
               ObjectsDeleteAll(0,0,OBJ_ARROW_THUMB_UP);
               ObjectsDeleteAll(0,0,OBJ_LABEL);
               return;
            }
            if(ObjectGetString(0,"escape2",OBJPROP_TEXT,0)=="0")
            {
               if(nowp>escape1)
               {
                  ObjectDelete(0,"escape1");
                  ObjectDelete(0,"escape1t");
                  ObjectDelete(0,"escapeS");
                  ObjectDelete(0,"escapeSt");
                  return;
               }
               if(period==2)
               {
                  zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
                  zig2=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
                  time2=Time_M5[ZigZagBuffer_pos_M5[2]];
               }
               if(period==3)
               {
                  zig1=ZigZagBuffer_M15[ZigZagBuffer_pos_M15[1]];
                  zig2=ZigZagBuffer_M15[ZigZagBuffer_pos_M15[2]];
                  time2=Time_M15[ZigZagBuffer_pos_M15[2]];
               }
               if((zig1>zig2)&&(time2>=estime))
               {
                  point2_=DoubleToString(zig2,8);
                  ObjectSetString(0,"escape2",OBJPROP_TEXT,point2_);
                  ObjectCreate(0,"escape2t",OBJ_ARROW_THUMB_UP,0,time2,zig2);
                  return;
               }
            }
            else
            {
                if(nowp>escape1)
                {
                   ObjectDelete(0,"escape1");
                   ObjectDelete(0,"escape1t");
                   ObjectDelete(0,"escapeS");
                   ObjectDelete(0,"escapeSt");
                   ObjectDelete(0,"escape2");
                   ObjectDelete(0,"escape2t");
                   return;
                }
                escape2=StringToDouble(ObjectGetString(0,"escape2",OBJPROP_TEXT,0));
                zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
                zig2=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
                time3=Time_M5[ZigZagBuffer_pos_M5[2]+2];
                int flag_2to3=0;
                for(i=0;i<tlines_U;i++)
                {
                    if((Time_M1[LineShow_U[i][1]]>estime)&&(Low_M1[LineShow_U[i][1]]<escape2+(nowp-escape2)/3))
                    {
                       flag_2to3=1; 
                       break;
                    }
                }
                if((flag_2to3==1)&&(i<tlines_D))
                {
                   dis=LineShow_U[i][0]-LineShow_U[i][1];
                   if(dis!=0)
                   {
                      div=Low_M1[LineShow_U[i][0]]-Low_M1[LineShow_U[i][1]];
                      breakP1=div*(barsnum_M1-1-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                      breakP3=div*(barsnum_M1-3-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                      breakP4=div*(barsnum_M1-4-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                      if(nowp<breakP1-50*d_point)
                      {
                         close_buy();
                         Alert("123出剩下一半");
                         ObjectsDeleteAll(0,0,OBJ_ARROW_THUMB_UP);
                         ObjectsDeleteAll(0,0,OBJ_LABEL);
                         return;
                      }
                      if(Low_M1[barsnum_M1-3]<breakP3-5*d_point)
                      {
                         if((nowp<Low_M1[barsnum_M1-2]-5*d_point)&&(Low_M1[barsnum_M1-2]<Low_M1[barsnum_M1-3])&&(Low_M1[barsnum_M1-4]>=breakP4))
                         {
                              close_buy();
                              Alert("123出剩下一半");
                              ObjectsDeleteAll(0,0,OBJ_ARROW_THUMB_UP);
                              ObjectsDeleteAll(0,0,OBJ_LABEL);
                              return;
                          }
                      }
                   }
                }
                if((zig1<zig2)&&(time3>=estime)&&(nowp<escapeS))
                {
                   close_buy();
                   Alert("123出剩下一半");
                   ObjectsDeleteAll(0,0,OBJ_ARROW_THUMB_UP);
                   ObjectsDeleteAll(0,0,OBJ_LABEL);
                   return;
                }
            }
        }
     }
}

void escapeB0()
{
     double vol_full=0.46;
     if(yuanyou==true)vol_full=4.6;
     double point1,point2,point3;
     string point1_,point2_,point3_;
     datetime point1_po;
     string point1_po_;
     int point1_pos=0,point3_pos=0;
     string point1_pos_,point3_pos_;
     point1=StringToDouble(ObjectGetString(0,"point1",OBJPROP_TEXT,0));
     point2=StringToDouble(ObjectGetString(0,"point2",OBJPROP_TEXT,0));
     point3=StringToDouble(ObjectGetString(0,"point3",OBJPROP_TEXT,0));
     datetime point1_time=ObjectGetInteger(0,"point1t",OBJPROP_TIME,0);
     datetime deal_time=StringToTime(ObjectGetString(0,"deal_time",OBJPROP_TEXT,0));
     double nowp=SymbolInfoDouble(_Symbol,SYMBOL_BID);
     double vol=PositionGetDouble(POSITION_VOLUME);
     double profit=PositionGetDouble(POSITION_PROFIT);
     double sl=PositionGetDouble(POSITION_SL);
     double deal_price=PositionGetDouble(POSITION_PRICE_OPEN);
     string deal_price_;
     double kuan;
     double SL;
     double escapeS;
     string escapeS_;
     int i,dis;
     double div,breakP1,breakP3,breakP4,breakP11;
     double escape1,escape2;
     string escape1_,escape2_;
     datetime point2_time,escape2_time;
     datetime estime;
     int period;
     double zig1,zig2;
     datetime time1,time2,time3,time_po;
     string time1_,time2_;
     int escape1_pos;
     int flag_escape1_3=0;
     datetime timeS_2;
     double escape1_2,escape2_2;
     string escape1_2_,escape2_2_,timeS_2_;
     datetime time_ag;
     string time_ag_;
     datetime timeS_2to3;
     double escape1_2to3,escape2_2to3;
     string timeS_2to3_,escape1_2to3_,escape2_2to3_;
     double price_ag;
     string price_ag_;
     int position_num=PositionsTotal();
     ulong position_ticket;
     int position_i=position_num;
     int position_sell_num=0;
     while(position_i>0)
     {
        position_ticket=PositionGetTicket(position_i-1);//这是仓位的ticket
        positioninfo.SelectByTicket(position_ticket);
        if((positioninfo.Symbol()==_Symbol)&&(positioninfo.PositionType()==POSITION_TYPE_BUY))
        {
            position_sell_num++;
        }
        position_i--;
     }
     int flag_vol=0;
     if((position_sell_num>1)||(vol==vol_full))
     {
         flag_vol=1;
     }
     if((position_sell_num==1)&&(vol==vol_full/2))
     {
         flag_vol=2;
     }
     if((flag_vol==1)&&(ObjectGetString(0,"escape_ag",OBJPROP_TEXT,0)=="0"))//赚了15个点
     {
        if(ObjectGetString(0,"deal_price",OBJPROP_TEXT,0)=="0")
        {
           deal_price_=DoubleToString(deal_price,8);
           ObjectSetString(0,"deal_price",OBJPROP_TEXT,deal_price_);
        }
        if(ObjectGetString(0,"escape_mode",OBJPROP_TEXT,0)=="0")
        {
           if(profit>=vol_full*150)
           {
              ObjectSetString(0,"escape_mode",OBJPROP_TEXT,"1");
           }
        }
        if(ObjectGetString(0,"escape_mode",OBJPROP_TEXT,0)=="1")
        {
           if(profit>=vol_full*250)
           {
              ObjectSetString(0,"escape_mode",OBJPROP_TEXT,"2");
           }
        }
     }
     /*if(ObjectGetString(0,"escape_ag",OBJPROP_TEXT,0)!="0")
     {
        deal_price=StringToDouble(ObjectGetString(0,"deal_price",OBJPROP_TEXT,0));
        if((nowp<deal_price-0.30)&&(deal_price!=0))
        {
           ObjectSetString(0,"escape_mode",OBJPROP_TEXT,"2");
        }
     }*/
     if(ObjectGetString(0,"point3",OBJPROP_TEXT,0)!="0")//如果有2点、3点
     {
        for(i=barsnum_M1-1;i>barsnum_M1-50000;i--)
        {
            if((Low_M1[i]<=point3)&&(point3_pos==0))point3_pos=i;
            if((Low_M1[i]<=point1)&&(point1_pos==0))
            {
               point1_pos=i;
               break;
            }
        }
     }
     if(ObjectGetString(0,"escape_ag",OBJPROP_TEXT,0)=="0")//没接过单
     {
        if((ObjectGetString(0,"escape_mode",OBJPROP_TEXT,0)=="0")&&(flag_vol==1))//没赚15点,破1-3或更早的通路出1-S，之后下来在下沿出一半
        {
           if(ObjectGetString(0,"escapeS",OBJPROP_TEXT,0)=="0")
           {
              for(i=0;i<tlines_U;i++)
              {
                  if((LineShow_U[i][1]<point3_pos)&&(Low_M1[LineShow_U[i][1]]<point3))
                  break;
              }
              if(i<tlines_U)dis=LineShow_U[i][0]-LineShow_U[i][1];
              else dis=0;
              if(dis!=0)
              {
                 div=Low_M1[LineShow_U[i][0]]-Low_M1[LineShow_U[i][1]];
                 breakP1=div*(barsnum_M1-1-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                 breakP3=div*(barsnum_M1-3-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                 breakP4=div*(barsnum_M1-4-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                 if(nowp<breakP1-50*d_point)
                 {
                    escape1_pos=iHighest(High_M1,barsnum_M1-point1_pos,barsnum_M1-1);
                    escape1_=DoubleToString(High_M1[escape1_pos],8);
                    ObjectSetString(0,"escapeS",OBJPROP_TEXT,"1");
                    ObjectCreate(0,"escapeSt",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                    ObjectSetString(0,"escape1",OBJPROP_TEXT,escape1_);
                    ObjectCreate(0,"escape1t",OBJ_ARROW_THUMB_UP,0,Time_M1[escape1_pos],High_M1[escape1_pos]);
                    time1_=TimeToString(Time_M5[barsnum_M5-1]);
                    ObjectSetString(0,"estime_po",OBJPROP_TEXT,time1_);
                    return;
                 }
                 if(Low_M1[barsnum_M1-3]<breakP3-5*d_point)
                 {
                    if((nowp<Low_M1[barsnum_M1-2]-5*d_point)&&(Low_M1[barsnum_M1-2]<Low_M1[barsnum_M1-3])&&(Low_M1[barsnum_M1-4]>=breakP4))
                    {
                       escape1_pos=iHighest(High_M1,barsnum_M1-point1_pos,barsnum_M1-1);
                       escape1_=DoubleToString(High_M1[escape1_pos],8);
                       ObjectSetString(0,"escapeS",OBJPROP_TEXT,"1");
                       ObjectCreate(0,"escapeSt",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                       ObjectSetString(0,"escape1",OBJPROP_TEXT,escape1_);
                       ObjectCreate(0,"escape1t",OBJ_ARROW_THUMB_UP,0,Time_M1[escape1_pos],High_M1[escape1_pos]);
                       time1_=TimeToString(Time_M5[barsnum_M5-1]);
                       ObjectSetString(0,"estime_po",OBJPROP_TEXT,time1_);
                       return;
                    }
                 }
              }
           }
           else
           {
               escape1=StringToDouble(ObjectGetString(0,"escape1",OBJPROP_TEXT,0));
               time1=StringToTime(ObjectGetString(0,"estime_po",OBJPROP_TEXT,0));
               if(nowp>escape1)
               {
                  ObjectDelete(0,"escapeS");
                  ObjectDelete(0,"escapeSt");
                  ObjectDelete(0,"escape1");
                  ObjectDelete(0,"escape1t");
                  ObjectDelete(0,"estime_po");
                  return;
               }
               for(i=0;i<tlines_D;i++)
               {
                   if((Time_M1[LineShow_D[i][1]]<time1)&&(High_M1[LineShow_D[i][1]]>escape1-(escape1-nowp)/3))
                   {
                      flag_escape1_3=1;
                      break;
                   }
               }
               if(flag_escape1_3==1)
               {
                  dis=LineShow_D[i][0]-LineShow_D[i][1];
                  if(dis!=0)
                  {
                     div=High_M1[LineShow_D[i][0]]-High_M1[LineShow_D[i][1]];
                     breakP1=div*(barsnum_M1-1-LineShow_D[i][0])/dis+High_M1[LineShow_D[i][0]];
                     kuan=div*(LineShow_D[i][2]-LineShow_D[i][0])/dis+High_M1[LineShow_D[i][0]]-Low_M1[LineShow_D[i][2]];
                     if(nowp>breakP1-kuan/10)
                     {
                        fsell(0,vol_full/2);
                        closeby_buy();
                        Alert("没赚15点出一半");
                        ObjectDelete(0,"escapeS");
                        ObjectDelete(0,"escapeSt");
                        ObjectDelete(0,"escape1");
                        ObjectDelete(0,"escape1t");
                        ObjectDelete(0,"estime_po");
                        return;
                     }
                  }
               }
           }
        }
        if((ObjectGetString(0,"escape_mode",OBJPROP_TEXT,0)=="1")&&(flag_vol==1))//赚15点，破3-4出一半
        {
            for(i=0;i<tlines_U;i++)
            {
                if((LineShow_U[i][1]<point3_pos)||(Low_M1[LineShow_U[i][1]]<point3+(nowp-point3)/3))
                break;
            }
            if(i<tlines_U)dis=LineShow_U[i][0]-LineShow_U[i][1];
            else dis=0;
            if(dis!=0)
            {
               div=Low_M1[LineShow_U[i][0]]-Low_M1[LineShow_U[i][1]];
               breakP1=div*(barsnum_M1-1-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
               breakP3=div*(barsnum_M1-3-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
               breakP4=div*(barsnum_M1-4-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
               if(nowp<breakP1-50*d_point)
               {
                  fsell(0,vol_full/2);
                  closeby_buy();
                  Alert("赚15点，破3-4出一半");
                  return;
               }
               if(Low_M1[barsnum_M1-3]<breakP3-5*d_point)
               {
                  if((nowp<Low_M1[barsnum_M1-2]-5*d_point)&&(Low_M1[barsnum_M1-2]<Low_M1[barsnum_M1-3])&&(Low_M1[barsnum_M1-4]>=breakP4))
                  {
                      fsell(0,vol_full/2);
                      closeby_buy();
                      Alert("赚15点，破3-4出一半");
                      return; 
                  }
               }
           }
        }
        if((flag_vol==1)&&(ObjectGetString(0,"escape_mode",OBJPROP_TEXT,0)=="2"))//25点以上
        {
           if(profit>vol_full*500)
           {
              SL=PositionGetDouble(POSITION_PRICE_OPEN);
              if(sl>SL)trade.PositionModify(_Symbol,SL,0);
           }
           if(ObjectGetString(0,"escapeS",OBJPROP_TEXT,0)!="2")//破通道出1和S
           {
              for(i=0;i<tlines_U-1;i++)
              {
                  dis=LineShow_U[i][0]-LineShow_U[i][1];
                  if(dis!=0)
                  {
                     div=Low_M1[LineShow_U[i][0]]-Low_M1[LineShow_U[i][1]];
                     breakP1=div*(barsnum_M1-1-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                     dis=LineShow_U[i+1][0]-LineShow_U[i+1][1];
                     if(dis!=0)
                     {
                        div=Low_M1[LineShow_U[i+1][0]]-Low_M1[LineShow_U[i+1][1]];
                        breakP11=div*(barsnum_M1-1-LineShow_U[i+1][0])/dis+Low_M1[LineShow_U[i+1][0]];
                        if(breakP1-breakP11>200*d_point)break;
                     }
                     else break;
                  }
              }
              if(i<tlines_U)dis=LineShow_U[i][0]-LineShow_U[i][1];
              else dis=0;
              if(dis!=0)
              {
                 div=Low_M1[LineShow_U[i][0]]-Low_M1[LineShow_U[i][1]];
                 breakP1=div*(barsnum_M1-1-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                 breakP3=div*(barsnum_M1-3-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                 breakP4=div*(barsnum_M1-4-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                 if(nowp<breakP1-50*d_point)
                 {
                    ObjectSetString(0,"escapeS",OBJPROP_TEXT,"2");
                    if(ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]]<ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]])
                    {
                       zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
                       time1=Time_M5[ZigZagBuffer_pos_M5[2]];
                    }
                    else
                    {
                        zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
                        time1=Time_M5[ZigZagBuffer_pos_M5[1]];
                    }
                    escape1_=DoubleToString(zig1,8);
                    ObjectCreate(0,"escapeSt",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                    ObjectSetString(0,"escape1",OBJPROP_TEXT,escape1_);
                    ObjectCreate(0,"escape1t",OBJ_ARROW_THUMB_UP,0,time1,zig1);
                    time1_=TimeToString(Time_M5[barsnum_M5-1]);
                    ObjectSetString(0,"estime_po",OBJPROP_TEXT,time1_);
                    return;
                 }
                 if(Low_M1[barsnum_M1-3]<breakP3-5*d_point)
                 {
                    if((nowp<Low_M1[barsnum_M1-2]-5*d_point)&&(Low_M1[barsnum_M1-2]<Low_M1[barsnum_M1-3])&&(Low_M1[barsnum_M1-4]>=breakP4))
                    {
                       ObjectSetString(0,"escapeS",OBJPROP_TEXT,"2");
                       if(ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]]<ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]])
                       {
                          zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
                          time1=Time_M5[ZigZagBuffer_pos_M5[2]];
                       }
                       else
                       {
                           zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
                           time1=Time_M5[ZigZagBuffer_pos_M5[1]];
                       }
                       escape1_=DoubleToString(zig1,8);
                       ObjectCreate(0,"escapeSt",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                       ObjectSetString(0,"escape1",OBJPROP_TEXT,escape1_);
                       ObjectCreate(0,"escape1t",OBJ_ARROW_THUMB_UP,0,time1,zig1);
                       time1_=TimeToString(Time_M5[barsnum_M5-1]);
                       ObjectSetString(0,"estime_po",OBJPROP_TEXT,time1_);
                       return;
                    }
                 }
              }
           }
           if(ObjectGetString(0,"escapeS",OBJPROP_TEXT,0)=="1")
           {
              ObjectDelete(0,"escapeS");
              ObjectDelete(0,"escapeSt");
              ObjectDelete(0,"estime_po");
              ObjectDelete(0,"escape1");
              ObjectDelete(0,"escape1t");
              ObjectDelete(0,"escape2");
              ObjectDelete(0,"escape2t");
              return;
           }
           if(ObjectGetString(0,"escapeS",OBJPROP_TEXT,0)=="2")
           {
              if(ObjectGetString(0,"escape2",OBJPROP_TEXT,0)=="0")
              {
                 escape1=StringToDouble(ObjectGetString(0,"escape1",OBJPROP_TEXT,0));
                 time1=StringToTime(ObjectGetString(0,"estime_po",OBJPROP_TEXT,0));
                 if(nowp>escape1)
                 {
                    ObjectSetString(0,"escape2",OBJPROP_TEXT,"A");//代表打破1点
                    return;
                 }
                 zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
                 zig2=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
                 time2=Time_M5[ZigZagBuffer_pos_M5[2]];
                 if((zig1>zig2)&&(time2>=time1))
                 {
                    escape2_=DoubleToString(zig2,8);
                    ObjectSetString(0,"escape2",OBJPROP_TEXT,escape2_);
                    ObjectCreate(0,"escape2t",OBJ_ARROW_THUMB_UP,0,time2,zig2);
                    return;
                 }
             }
             else
             {
                 if(ObjectGetString(0,"escape2",OBJPROP_TEXT,0)=="A")//破最小的通道出
                 {
                    if(ObjectGetString(0,"beforeS_2",OBJPROP_TEXT,0)=="0")
                    {
                       i=0;
                       if(i<tlines_U)dis=LineShow_U[i][0]-LineShow_U[i][1];
                       else dis=0;
                       if(dis!=0)
                       {
                          div=Low_M1[LineShow_U[i][0]]-Low_M1[LineShow_U[i][1]];
                          breakP1=div*(barsnum_M1-1-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                          breakP3=div*(barsnum_M1-3-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                          breakP4=div*(barsnum_M1-4-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                          if(nowp<breakP1-50*d_point)
                          {
                             timeS_2_=TimeToString(Time_M5[barsnum_M5-1]);
                             escape1_2=High_M1[iHighest(High_M1,barsnum_M1-LineShow_U[i][1],barsnum_M1-1)];
                             escape1_2_=DoubleToString(escape1_2,8);
                             ObjectSetString(0,"beforeS_2",OBJPROP_TEXT,timeS_2_);
                             ObjectSetString(0,"escape1_2",OBJPROP_TEXT,escape1_2_);
                             ObjectCreate(0,"escapeS_2t",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                             return;
                          }
                          if(Low_M1[barsnum_M1-3]<breakP3-5*d_point)
                          {
                             if((nowp<Low_M1[barsnum_M1-2]-5*d_point)&&(Low_M1[barsnum_M1-2]<Low_M1[barsnum_M1-3])&&(Low_M1[barsnum_M1-4]>=breakP4))
                             {
                                timeS_2_=TimeToString(Time_M5[barsnum_M5-1]);
                                escape1_2=High_M1[iHighest(High_M1,barsnum_M1-LineShow_U[i][1],barsnum_M1-1)];
                                escape1_2_=DoubleToString(escape1_2,8);
                                ObjectSetString(0,"beforeS_2",OBJPROP_TEXT,timeS_2_);
                                ObjectSetString(0,"escape1_2",OBJPROP_TEXT,escape1_2_);
                                ObjectCreate(0,"escapeS_2t",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                                return;
                             }
                          }
                       }
                    }
                    else
                    {
                        escape1_2=StringToDouble(ObjectGetString(0,"escape1_2",OBJPROP_TEXT,0));
                        if(nowp>escape1_2)
                        {
                           ObjectDelete(0,"beforeS_2");
                           ObjectDelete(0,"escape1_2");
                           ObjectDelete(0,"escapeS_2t");
                           ObjectDelete(0,"escape2_2");
                           ObjectDelete(0,"escape2_2t");
                           return;
                        }
                        if(ObjectGetString(0,"escape2_2",OBJPROP_TEXT,0)=="0")
                        {
                           escape2_2_=DoubleToString(nowp,8);
                           ObjectSetString(0,"escape2_2",OBJPROP_TEXT,escape2_2_);
                           ObjectCreate(0,"escape2_2t",OBJ_ARROW_THUMB_UP,0,Time_M5[barsnum_M5-1],nowp);
                           return;
                        }
                        else
                        {
                           escape2_2=StringToDouble(ObjectGetString(0,"escape2_2",OBJPROP_TEXT,0));
                           timeS_2=StringToTime(ObjectGetString(0,"beforeS_2",OBJPROP_TEXT,0));
                           if(Time_M5[barsnum_M5-2]>timeS_2)
                           {
                              if(Low_M5[barsnum_M5-2]<escape2_2)
                              {
                                 escape2_2_=DoubleToString(Low_M5[barsnum_M5-2],8);
                                 ObjectSetString(0,"escape2_2",OBJPROP_TEXT,escape2_2_);
                                 ObjectSetDouble(0,"escape2_2t",OBJPROP_PRICE,Low_M5[barsnum_M5-2]);
                                 ObjectSetInteger(0,"escape2_2t",OBJPROP_TIME,Time_M5[barsnum_M5-2]);
                                 return;
                              }
                              if((Low_M5[barsnum_M5-2]>=escape2_2)&&(nowp<escape2_2))
                              {
                                 fsell(0,vol_full/2);
                                 closeby_buy();
                                 ObjectDelete(0,"escape_mode");
                                 ObjectDelete(0,"escapeS");
                                 ObjectDelete(0,"escapeSt");
                                 ObjectDelete(0,"estime_po");
                                 ObjectDelete(0,"escape1");
                                 ObjectDelete(0,"escape1t");
                                 ObjectDelete(0,"escape2");
                                 ObjectDelete(0,"escape2t");
                                 ObjectDelete(0,"beforeS_2");
                                 ObjectDelete(0,"escape1_2");
                                 ObjectDelete(0,"escapeS_2t");
                                 ObjectDelete(0,"escape2_2");
                                 ObjectDelete(0,"escape2_2t");
                                 Alert("25点以上左侧+123出场");
                                 return;
                              }
                           }
                        }
                    }
                 }
                 else//等下来以后破最小的通道出
                 {
                     escape1=StringToDouble(ObjectGetString(0,"escape1",OBJPROP_TEXT,0));
                     time1=StringToTime(ObjectGetString(0,"estime_po",OBJPROP_TEXT,0));
                     if(nowp>escape1)
                     {
                        ObjectSetString(0,"escape2",OBJPROP_TEXT,"A");//代表打破1点
                        return;
                     }
                     escape2=StringToDouble(ObjectGetString(0,"escape2",OBJPROP_TEXT,0));
                     zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
                     zig2=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
                     time2=Time_M5[ZigZagBuffer_pos_M5[2]];
                     escape2_time=ObjectGetInteger(0,"escape2t",OBJPROP_TIME,0);
                     if((zig1<zig2)&&(time2>=escape2_time))
                     {
                        close_buy();
                        Alert("25点以上，123全出");
                        ObjectsDeleteAll(0,0,OBJ_ARROW_THUMB_UP);
                        ObjectsDeleteAll(0,0,OBJ_LABEL);
                        return;
                     }
                  }
              }
           }
        }
     }
     if((ObjectGetString(0,"escape_ag",OBJPROP_TEXT,0)!="0")&&(flag_vol==1))//接过单,破接单之前的通道123出一半，(或者破外面的通道直接全出)
     {
         price_ag=StringToDouble(ObjectGetString(0,"price_ag",OBJPROP_TEXT,0));
         time_ag=StringToTime(ObjectGetString(0,"escape_ag",OBJPROP_TEXT,0));
         if(ObjectGetString(0,"escape_mode",OBJPROP_TEXT,0)!="2")
         {
            if(nowp-price_ag>=250*d_point)ObjectSetString(0,"escape_mode",OBJPROP_TEXT,"2");
            else ObjectSetString(0,"escape_mode",OBJPROP_TEXT,"1");
         }
         if(ObjectGetString(0,"escape_mode",OBJPROP_TEXT,0)=="0")
         {
            i=0;
            if(i<tlines_U)dis=LineShow_U[i][0]-LineShow_U[i][1];
            else dis=0;
            if(dis!=0)
            {
               div=Low_M1[LineShow_U[i][0]]-Low_M1[LineShow_U[i][1]];
               breakP1=div*(barsnum_M1-1-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
               breakP3=div*(barsnum_M1-3-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
               breakP4=div*(barsnum_M1-4-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
               if(nowp<breakP1-70*d_point)
               {
                  fsell(0,vol_full/2);
                  closeby_buy();
                  Alert("接单后亏损，破最小通路出一半");
                  return;
               }
               if(Low_M1[barsnum_M1-3]<breakP3-5*d_point)
               {
                  if((nowp<Low_M1[barsnum_M1-2]-5*d_point)&&(Low_M1[barsnum_M1-2]<Low_M1[barsnum_M1-3])&&(Low_M1[barsnum_M1-4]>=breakP4))
                  {
                     fsell(0,vol_full/2);
                     closeby_buy();
                     Alert("接单后亏损，破最小通路出一半");
                     return; 
                  }
               }
            }
         }
         if(ObjectGetString(0,"escape_mode",OBJPROP_TEXT,0)=="1")
         {
            for(i=0;i<tlines_U;i++)
            {
                if((LineShow_U[i][1]<point3_pos)||(Low_M1[LineShow_U[i][1]]<point3+(nowp-point3)/3))
                break;
            }
            if(i<tlines_U)dis=LineShow_U[i][0]-LineShow_U[i][1];
            else dis=0;
            if(dis!=0)
            {
               div=Low_M1[LineShow_U[i][0]]-Low_M1[LineShow_U[i][1]];
               breakP1=div*(barsnum_M1-1-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
               breakP3=div*(barsnum_M1-3-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
               breakP4=div*(barsnum_M1-4-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
               if(nowp<breakP1-50*d_point)
               {
                  fsell(0,vol_full/2);
                  closeby_buy();
                  Alert("接单后，破3-4出一半");
                  return;
               }
               if(Low_M1[barsnum_M1-3]<breakP3-5*d_point)
               {
                  if((nowp<Low_M1[barsnum_M1-2]-5*d_point)&&(Low_M1[barsnum_M1-2]<Low_M1[barsnum_M1-3])&&(Low_M1[barsnum_M1-4]>=breakP4))
                  {
                     fsell(0,vol_full/2);
                     closeby_buy();
                     Alert("接单后，破3-4出一半");
                     return; 
                  }
               }
            }
         }
         if(ObjectGetString(0,"escape_mode",OBJPROP_TEXT,0)=="2")
         {
            if(ObjectGetString(0,"escape",OBJPROP_TEXT,0)=="0")
            {
               time_ag=StringToTime(ObjectGetString(0,"escape_ag",OBJPROP_TEXT,0));
               for(i=0;i<tlines_U;i++)
               {
                   if(Time_M1[LineShow_U[i][1]]<time_ag)break;
               }
               if((middle_TL>0)&&(middle_TL-1<i))i=middle_TL-1;
               if(i<tlines_U)dis=LineShow_U[i][0]-LineShow_U[i][1];
               else dis=0;
               if(dis!=0)
               {
                  div=Low_M1[LineShow_U[i][0]]-Low_M1[LineShow_U[i][1]];
                  breakP1=div*(barsnum_M1-1-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                  breakP3=div*(barsnum_M1-3-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                  breakP4=div*(barsnum_M1-4-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                  if(nowp<breakP1-50*d_point)
                  {
                     ObjectSetString(0,"escape",OBJPROP_TEXT,"1");
                     if(i==middle_TL-1)
                        ObjectSetString(0,"escape",OBJPROP_TEXT,"2");
                     escapeS_=DoubleToString(breakP1,8);
                     ObjectSetString(0,"escapeS",OBJPROP_TEXT,escapeS_);
                     if(ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]]<ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]])
                     {
                        zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
                        time1=Time_M5[ZigZagBuffer_pos_M5[2]];
                     }
                     else
                     {
                         zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
                         time1=Time_M5[ZigZagBuffer_pos_M5[1]];
                     }
                     escape1_=DoubleToString(zig1,8);
                     ObjectCreate(0,"escapeSt",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                     ObjectSetString(0,"escape1",OBJPROP_TEXT,escape1_);
                     ObjectCreate(0,"escape1t",OBJ_ARROW_THUMB_UP,0,time1,zig1);
                     time1_=TimeToString(Time_M5[barsnum_M5-1]);
                     ObjectSetString(0,"estime_po",OBJPROP_TEXT,time1_);
                     return;
                  }
                  if(Low_M1[barsnum_M1-3]<breakP3-5*d_point)
                  {
                     if((nowp<Low_M1[barsnum_M1-2]-5*d_point)&&(Low_M1[barsnum_M1-2]<Low_M1[barsnum_M1-3])&&(Low_M1[barsnum_M1-4]>=breakP4))
                     {
                        ObjectSetString(0,"escape",OBJPROP_TEXT,"1");
                        if(i==middle_TL-1)
                           ObjectSetString(0,"escape",OBJPROP_TEXT,"2");
                        escapeS_=DoubleToString(breakP1,8);
                        ObjectSetString(0,"escapeS",OBJPROP_TEXT,escapeS_);
                        if(ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]]<ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]])
                        {
                           zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
                           time1=Time_M5[ZigZagBuffer_pos_M5[2]];
                        }
                        else
                        {
                            zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
                            time1=Time_M5[ZigZagBuffer_pos_M5[1]];
                        }
                        escape1_=DoubleToString(zig1,8);
                        ObjectCreate(0,"escapeSt",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                        ObjectSetString(0,"escape1",OBJPROP_TEXT,escape1_);
                        ObjectCreate(0,"escape1t",OBJ_ARROW_THUMB_UP,0,time1,zig1);
                        time1_=TimeToString(Time_M5[barsnum_M5-1]);
                        ObjectSetString(0,"estime_po",OBJPROP_TEXT,time1_);
                        return;
                    }
                  }
               }
            }
            else
            {
                escapeS=StringToDouble(ObjectGetString(0,"escapeS",OBJPROP_TEXT,0));
                escape1=StringToDouble(ObjectGetString(0,"escape1",OBJPROP_TEXT,0));
                estime=StringToTime(ObjectGetString(0,"estime_po",OBJPROP_TEXT,0));
                if(nowp>escape1)
                {
                   ObjectDelete(0,"escape");
                   ObjectDelete(0,"escapeS");
                   ObjectDelete(0,"escapeSt");
                   ObjectDelete(0,"estime_po");
                   ObjectDelete(0,"escape1");
                   ObjectDelete(0,"escape1t");
                   ObjectDelete(0,"escape2");
                   ObjectDelete(0,"escape2t");
                   ObjectDelete(0,"escapeS_2to3");
                   ObjectDelete(0,"escape1_2to3");
                   ObjectDelete(0,"escapeS_2to3t");
                   ObjectDelete(0,"escape2_2to3");
                   ObjectDelete(0,"escape2_2to3t");
                   return;
                }
                if(ObjectGetString(0,"escape2",OBJPROP_TEXT,0)=="0")
                {
                   zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
                   zig2=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
                   time2=Time_M5[ZigZagBuffer_pos_M5[2]];
                   if((zig1>zig2)&&(time2>=estime))
                   {
                     point2_=DoubleToString(zig2,8);
                     ObjectSetString(0,"escape2",OBJPROP_TEXT,point2_);
                     ObjectCreate(0,"escape2t",OBJ_ARROW_THUMB_UP,0,time2,zig2);
                     return;
                   }
                }
                else
                {
                    if(ObjectGetString(0,"escape",OBJPROP_TEXT,0)=="1")vol_now=vol_full/2;
                    if(ObjectGetString(0,"escape",OBJPROP_TEXT,0)=="2")vol_now=vol_full;
                    escape2=StringToDouble(ObjectGetString(0,"escape2",OBJPROP_TEXT,0));
                    zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
                    zig2=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
                    time3=Time_M5[ZigZagBuffer_pos_M5[2]+2];
                    int flag_2to3=0;
                    for(i=0;i<tlines_U;i++)
                    {
                        if((Time_M1[LineShow_U[i][1]]>estime)&&(Low_M1[LineShow_U[i][1]]<escape2+(nowp-escape2)/3))
                        {
                           flag_2to3=1; 
                           break;
                        }
                    }
                    if(ObjectGetString(0,"escapeS_2to3",OBJPROP_TEXT,0)=="0")
                    {
                       if((flag_2to3==1)&&(i<tlines_U))
                       {
                          dis=LineShow_U[i][0]-LineShow_U[i][1];
                          if(dis!=0)
                          {
                             div=Low_M1[LineShow_U[i][0]]-Low_M1[LineShow_U[i][1]];
                             breakP1=div*(barsnum_M1-1-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                             breakP3=div*(barsnum_M1-3-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                             breakP4=div*(barsnum_M1-4-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                          }
                          if(nowp<breakP1-50*d_point)
                          {
                             timeS_2to3_=TimeToString(Time_M5[barsnum_M5-1]);
                             escape1_2to3=High_M1[iHighest(High_M1,barsnum_M1-LineShow_U[i][1],barsnum_M1-1)];
                             escape1_2to3_=DoubleToString(escape1_2to3,8);
                             ObjectSetString(0,"escapeS_2to3",OBJPROP_TEXT,timeS_2to3_);
                             ObjectSetString(0,"escape1_2to3",OBJPROP_TEXT,escape1_2to3_);
                             ObjectCreate(0,"escapeS_2to3t",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                             return;
                          }
                          if(Low_M1[barsnum_M1-3]<breakP3-5*d_point)
                          {
                             if((nowp<Low_M1[barsnum_M1-2]-5*d_point)&&(Low_M1[barsnum_M1-2]<Low_M1[barsnum_M1-3])&&(Low_M1[barsnum_M1-4]>=breakP4))
                             {
                                  timeS_2to3_=TimeToString(Time_M5[barsnum_M5-1]);
                                  escape1_2to3=High_M1[iHighest(High_M1,barsnum_M1-LineShow_U[i][1],barsnum_M1-1)];
                                  escape1_2to3_=DoubleToString(escape1_2to3,8);
                                  ObjectSetString(0,"escapeS_2to3",OBJPROP_TEXT,timeS_2to3_);
                                  ObjectSetString(0,"escape1_2to3",OBJPROP_TEXT,escape1_2to3_);
                                  ObjectCreate(0,"escapeS_2to3t",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                                  return;
                              }
                          }
                       }
                    }
                    else
                    {
                        escape1_2to3=StringToDouble(ObjectGetString(0,"escape1_2to3",OBJPROP_TEXT,0));
                        if(nowp>escape1_2to3)
                        {
                           ObjectDelete(0,"escapeS_2to3");
                           ObjectDelete(0,"escape1_2to3");
                           ObjectDelete(0,"escapeS_2to3t");
                           ObjectDelete(0,"escape2_2to3");
                           ObjectDelete(0,"escape2_2to3t");
                           return;
                        }
                        if(ObjectGetString(0,"escape2_2to3",OBJPROP_TEXT,0)=="0")
                        {
                           escape2_2to3_=DoubleToString(nowp,8);
                           ObjectSetString(0,"escape2_2to3",OBJPROP_TEXT,escape2_2to3_);
                           ObjectCreate(0,"escape2_2to3t",OBJ_ARROW_THUMB_UP,0,Time_M5[barsnum_M5-1],nowp);
                           return;
                        }
                       else
                       {
                            escape2_2to3=StringToDouble(ObjectGetString(0,"escape2_2to3",OBJPROP_TEXT,0));
                            timeS_2to3=StringToTime(ObjectGetString(0,"escapeS_2to3",OBJPROP_TEXT,0));
                            if(Time_M5[barsnum_M5-2]>timeS_2to3)
                            {
                               if(Low_M5[barsnum_M5-2]<escape2_2to3)
                               {
                                  escape2_2to3_=DoubleToString(Low_M5[barsnum_M5-2],8);
                                  ObjectSetString(0,"escape2_2to3",OBJPROP_TEXT,escape2_2to3_);
                                  ObjectSetDouble(0,"escape2_2to3t",OBJPROP_PRICE,Low_M5[barsnum_M5-2]);
                                  ObjectSetInteger(0,"escape2_2to3t",OBJPROP_TIME,Time_M5[barsnum_M5-2]);
                                  return;
                               }
                               if((Low_M5[barsnum_M5-2]>=escape2_2to3)&&(nowp<escape2_2to3))
                               {
                                  close_buy();
                                  Alert("接单以后破中通道2次123全出");
                                  ObjectDelete(0,"escape");
                                  ObjectDelete(0,"escapeS");
                                  ObjectDelete(0,"escapeSt");
                                  ObjectDelete(0,"estime_po");
                                  ObjectDelete(0,"escape1");
                                  ObjectDelete(0,"escape1t");
                                  ObjectDelete(0,"escape2");
                                  ObjectDelete(0,"escape2t");
                                  ObjectDelete(0,"escapeS_2to3");
                                  ObjectDelete(0,"escapeS_2to3t");
                                  ObjectDelete(0,"escape2_2to3");
                                  ObjectDelete(0,"escape2_2to3t");
                                  return;
                               }
                            }
                        }
                    }
                    if((zig1<zig2)&&(time3>=estime)&&(nowp<escapeS))
                    {
                       close_buy();
                       Alert("接单以后破通道123全出，Z字线123");
                       ObjectDelete(0,"escape");
                       ObjectDelete(0,"escapeS");
                       ObjectDelete(0,"escapeSt");
                       ObjectDelete(0,"estime_po");
                       ObjectDelete(0,"escape1");
                       ObjectDelete(0,"escape1t");
                       ObjectDelete(0,"escape2");
                       ObjectDelete(0,"escape2t");
                       ObjectDelete(0,"escapeS_2to3");
                       ObjectDelete(0,"escapeS_2to3t");
                       ObjectDelete(0,"escape2_2to3");
                       ObjectDelete(0,"escape2_2to3t");
                       return;
                    }
                }
            }
        }
     }
     if(flag_vol==2)
     {
        i=barsnum_M1-1;
        while((Time_M1[i]>deal_time)&&(Time_M1[i]>Time_D1[barsnum_D1-10]))
        {
              i--;
        }
        int pointh_pos=iHighest(High_M1,barsnum_M1-i,barsnum_M1-5);
        double pointh=High_M1[pointh_pos];
        double pointl;
        if(ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]]<ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]])
           pointl=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
        else pointl=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
        if(nowp>pointh)
        {
           time_ag_=TimeToString(Time_M5[barsnum_M5-1]);
           ObjectSetString(0,"escape_ag",OBJPROP_TEXT,time_ag_);
           price_ag_=DoubleToString(pointl,8);
           ObjectSetString(0,"price_ag",OBJPROP_TEXT,price_ag_);
           fbuy(sl,vol_full/2);
           Alert("接一半");
           ObjectDelete(0,"escape_mode");
           ObjectDelete(0,"escapeS");
           ObjectDelete(0,"escapeSt");
           ObjectDelete(0,"estime_po");
           ObjectDelete(0,"escape1");
           ObjectDelete(0,"escape1t");
           ObjectDelete(0,"escape2");
           ObjectDelete(0,"escape2t");
           return;
        }
        if(ObjectGetString(0,"escape1_2to3",OBJPROP_TEXT,0)!="0")
        {
           escape1_2to3=StringToDouble(ObjectGetString(0,"escape1_2to3",OBJPROP_TEXT,0));
           if(nowp>escape1_2to3)
           {
              time_ag_=TimeToString(Time_M5[barsnum_M5-1]);
              ObjectSetString(0,"escape_ag",OBJPROP_TEXT,time_ag_);
              price_ag_=DoubleToString(pointl,8);
              ObjectSetString(0,"price_ag",OBJPROP_TEXT,price_ag_);
              fbuy(sl,vol_full/2);
              Alert("双123的接单");
              ObjectDelete(0,"escape_mode");
              ObjectDelete(0,"escapeS");
              ObjectDelete(0,"escapeSt");
              ObjectDelete(0,"estime_po");
              ObjectDelete(0,"escape1");
              ObjectDelete(0,"escape1t");
              ObjectDelete(0,"escape2");
              ObjectDelete(0,"escape2t");
              ObjectDelete(0,"escape1_2to3");
              return;
           }
        }
        if(ObjectGetString(0,"escapeS",OBJPROP_TEXT,0)=="0")
        {
           for(i=0;i<tlines_U-1;i++)
           {
               dis=LineShow_U[i][0]-LineShow_U[i][1];
               if(dis!=0)
               {
                  div=Low_M1[LineShow_U[i][0]]-Low_M1[LineShow_U[i][1]];
                  breakP1=div*(barsnum_M1-1-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                  dis=LineShow_U[i+1][0]-LineShow_U[i+1][1];
                  if(dis!=0)
                  {
                     div=Low_M1[LineShow_U[i+1][0]]-Low_M1[LineShow_U[i+1][1]];
                     breakP11=div*(barsnum_M1-1-LineShow_U[i+1][0])/dis+Low_M1[LineShow_U[i+1][0]];
                     if(breakP1-breakP11>200*d_point)break;
                  }
                  else break;
               }
           }
           if(big_TL>0)
           {
              datetime nowtime=SymbolInfoInteger(_Symbol,SYMBOL_TIME);//当前时间
              HistorySelect(Time_H4[barsnum_H4-60],nowtime);
              int order_num=HistoryOrdersTotal();//选择的历史区间内总交易次数
              int ticket=HistoryOrderGetTicket(order_num-1);//这是选择订单的ticket
              datetime last_deal_time=HistoryOrderGetInteger(ticket,ORDER_TIME_DONE);
              if(HistoryOrderGetInteger(ticket,ORDER_TYPE)==ORDER_TYPE_SELL)
              {
                 for(i=0;i<tlines_U;i++)
                 {
                     if(Time_M1[LineShow_U[i][1]]<last_deal_time)break;
                 }
              }
           }
           if(i<tlines_U)dis=LineShow_U[i][0]-LineShow_U[i][1];
           else dis=0;
           if(dis!=0)
           {
              div=Low_M1[LineShow_U[i][0]]-Low_M1[LineShow_U[i][1]];
              breakP1=div*(barsnum_M1-1-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
              breakP3=div*(barsnum_M1-3-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
              breakP4=div*(barsnum_M1-4-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
              if(nowp<breakP1-50*d_point)
              {
                 escapeS_=DoubleToString(breakP1,8);
                 ObjectSetString(0,"escapeS",OBJPROP_TEXT,escapeS_);
                 ObjectCreate(0,"escapeSt",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                 findperiod2();
                 return;
              }
              if(Low_M1[barsnum_M1-3]<breakP3-5*d_point)
              {
                 if((nowp<Low_M1[barsnum_M1-2]-5*d_point)&&(Low_M1[barsnum_M1-2]<Low_M1[barsnum_M1-3])&&(Low_M1[barsnum_M1-4]>=breakP4))
                 {
                    escapeS_=DoubleToString(breakP1,8);
                    ObjectSetString(0,"escapeS",OBJPROP_TEXT,escapeS_);
                    ObjectCreate(0,"escapeSt",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                    findperiod2();
                    return;
                 }
              }
           }
        }
        else
        {
            escapeS=StringToDouble(ObjectGetString(0,"escapeS",OBJPROP_TEXT,0));
            escape1=StringToDouble(ObjectGetString(0,"escape1",OBJPROP_TEXT,0));
            estime=StringToTime(ObjectGetString(0,"estime_po",OBJPROP_TEXT,0));
            period=StringToInteger(ObjectGetString(0,"trade_period",OBJPROP_TEXT,0));
            if((nowp<escapeS-(escape1-escapeS)/3*2)&&(escape1-escapeS>200*d_point)&&(big_TL<0))
            {
               close_buy();
               Alert("2/3出剩下一半");
               ObjectsDeleteAll(0,0,OBJ_ARROW_THUMB_UP);
               ObjectsDeleteAll(0,0,OBJ_LABEL);
               return;
            }
            if(ObjectGetString(0,"escape2",OBJPROP_TEXT,0)=="0")
            {
               if(nowp>escape1)
               {
                  ObjectDelete(0,"escape1");
                  ObjectDelete(0,"escape1t");
                  ObjectDelete(0,"escapeS");
                  ObjectDelete(0,"escapeSt");
                  return;
               }
               if(period==2)
               {
                  zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
                  zig2=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
                  time2=Time_M5[ZigZagBuffer_pos_M5[2]];
               }
               if(period==3)
               {
                  zig1=ZigZagBuffer_M15[ZigZagBuffer_pos_M15[1]];
                  zig2=ZigZagBuffer_M15[ZigZagBuffer_pos_M15[2]];
                  time2=Time_M15[ZigZagBuffer_pos_M15[2]];
               }
               if((zig1>zig2)&&(time2>=estime))
               {
                  point2_=DoubleToString(zig2,8);
                  ObjectSetString(0,"escape2",OBJPROP_TEXT,point2_);
                  ObjectCreate(0,"escape2t",OBJ_ARROW_THUMB_UP,0,time2,zig2);
                  return;
               }
            }
            else
            {
                if(nowp>escape1)
                {
                   ObjectDelete(0,"escape1");
                   ObjectDelete(0,"escape1t");
                   ObjectDelete(0,"escapeS");
                   ObjectDelete(0,"escapeSt");
                   ObjectDelete(0,"escape2");
                   ObjectDelete(0,"escape2t");
                   return;
                }
                escape2=StringToDouble(ObjectGetString(0,"escape2",OBJPROP_TEXT,0));
                zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
                zig2=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
                time3=Time_M5[ZigZagBuffer_pos_M5[2]+2];
                int flag_2to3=0;
                for(i=0;i<tlines_U;i++)
                {
                    if((Time_M1[LineShow_U[i][1]]>estime)&&(Low_M1[LineShow_U[i][1]]<escape2+(nowp-escape2)/3))
                    {
                       flag_2to3=1; 
                       break;
                    }
                }
                if((flag_2to3==1)&&(i<tlines_D))
                {
                   dis=LineShow_U[i][0]-LineShow_U[i][1];
                   if(dis!=0)
                   {
                      div=Low_M1[LineShow_U[i][0]]-Low_M1[LineShow_U[i][1]];
                      breakP1=div*(barsnum_M1-1-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                      breakP3=div*(barsnum_M1-3-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                      breakP4=div*(barsnum_M1-4-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                      if(nowp<breakP1-50*d_point)
                      {
                         close_buy();
                         Alert("123出剩下一半");
                         ObjectsDeleteAll(0,0,OBJ_ARROW_THUMB_UP);
                         ObjectsDeleteAll(0,0,OBJ_LABEL);
                         return;
                      }
                      if(Low_M1[barsnum_M1-3]<breakP3-5*d_point)
                      {
                         if((nowp<Low_M1[barsnum_M1-2]-5*d_point)&&(Low_M1[barsnum_M1-2]<Low_M1[barsnum_M1-3])&&(Low_M1[barsnum_M1-4]>=breakP4))
                         {
                              close_buy();
                              Alert("123出剩下一半");
                              ObjectsDeleteAll(0,0,OBJ_ARROW_THUMB_UP);
                              ObjectsDeleteAll(0,0,OBJ_LABEL);
                              return;
                          }
                      }
                   }
                }
                if((zig1<zig2)&&(time3>=estime)&&(nowp<escapeS))
                {
                   close_buy();
                   Alert("123出剩下一半");
                   ObjectsDeleteAll(0,0,OBJ_ARROW_THUMB_UP);
                   ObjectsDeleteAll(0,0,OBJ_LABEL);
                   return;
                }
            }
        }
     }
}


void escapeB1()
{
     double vol_full=0.44;
     if(yuanyou==true)vol_full=4.4;
     double point1,point2,point3;
     string point1_,point2_,point3_;
     datetime point1_po;
     string point1_po_;
     int point1_pos=0,point3_pos=0;
     string point1_pos_,point3_pos_;
     point1=StringToDouble(ObjectGetString(0,"point1",OBJPROP_TEXT,0));
     point2=StringToDouble(ObjectGetString(0,"point2",OBJPROP_TEXT,0));
     point3=StringToDouble(ObjectGetString(0,"point3",OBJPROP_TEXT,0));
     datetime point1_time=ObjectGetInteger(0,"point1t",OBJPROP_TIME,0);
     datetime deal_time=StringToTime(ObjectGetString(0,"deal_time",OBJPROP_TEXT,0));
     double nowp=SymbolInfoDouble(_Symbol,SYMBOL_BID);
     double vol=PositionGetDouble(POSITION_VOLUME);
     double profit=PositionGetDouble(POSITION_PROFIT);
     double sl=PositionGetDouble(POSITION_SL);
     double deal_price=PositionGetDouble(POSITION_PRICE_OPEN);
     string deal_price_;
     double kuan;
     double SL;
     double escapeS;
     string escapeS_;
     int i,dis;
     double div,breakP1,breakP3,breakP4,breakP11;
     double escape1,escape2;
     string escape1_,escape2_;
     datetime point2_time,escape2_time;
     datetime estime;
     int period;
     double zig1,zig2;
     datetime time1,time2,time3,time_po;
     string time1_,time2_;
     int escape1_pos;
     int flag_escape1_3=0;
     datetime timeS_2;
     double escape1_2,escape2_2;
     string escape1_2_,escape2_2_,timeS_2_;
     datetime time_ag;
     string time_ag_;
     datetime timeS_2to3;
     double escape1_2to3,escape2_2to3;
     string timeS_2to3_,escape1_2to3_,escape2_2to3_;
     double price_ag;
     string price_ag_;
     int position_num=PositionsTotal();
     ulong position_ticket;
     int position_i=position_num;
     int position_sell_num=0;
     while(position_i>0)
     {
        position_ticket=PositionGetTicket(position_i-1);//这是仓位的ticket
        positioninfo.SelectByTicket(position_ticket);
        if((positioninfo.Symbol()==_Symbol)&&(positioninfo.PositionType()==POSITION_TYPE_BUY))
        {
            position_sell_num++;
        }
        position_i--;
     }
     int flag_vol=0;
     if((position_sell_num>1)||(vol==vol_full))
     {
         flag_vol=1;
     }
     if((position_sell_num==1)&&(vol==vol_full/2))
     {
         flag_vol=2;
     }
     if((flag_vol==1)&&(ObjectGetString(0,"escape_ag",OBJPROP_TEXT,0)=="0"))//赚了15个点
     {
        if(ObjectGetString(0,"deal_price",OBJPROP_TEXT,0)=="0")
        {
           deal_price_=DoubleToString(deal_price,8);
           ObjectSetString(0,"deal_price",OBJPROP_TEXT,deal_price_);
        }
        if(ObjectGetString(0,"escape_mode",OBJPROP_TEXT,0)=="0")
        {
           if(profit>=vol_full*150)
           {
              ObjectSetString(0,"escape_mode",OBJPROP_TEXT,"1");
           }
        }
        if(ObjectGetString(0,"escape_mode",OBJPROP_TEXT,0)=="1")
        {
           if(profit>=vol_full*250)
           {
              ObjectSetString(0,"escape_mode",OBJPROP_TEXT,"2");
           }
        }
     }
     /*if(ObjectGetString(0,"escape_ag",OBJPROP_TEXT,0)!="0")
     {
        deal_price=StringToDouble(ObjectGetString(0,"deal_price",OBJPROP_TEXT,0));
        if((nowp<deal_price-0.30)&&(deal_price!=0))
        {
           ObjectSetString(0,"escape_mode",OBJPROP_TEXT,"2");
        }
     }*/
     if(ObjectGetString(0,"point3",OBJPROP_TEXT,0)!="0")//如果有2点、3点
     {
        for(i=barsnum_M1-1;i>barsnum_M1-50000;i--)
        {
            if((Low_M1[i]<=point3)&&(point3_pos==0))point3_pos=i;
            if((Low_M1[i]<=point1)&&(point1_pos==0))
            {
               point1_pos=i;
               break;
            }
        }
     }
     if(ObjectGetString(0,"escape_ag",OBJPROP_TEXT,0)=="0")//没接过单
     {
        if((ObjectGetString(0,"escape_mode",OBJPROP_TEXT,0)=="0")&&(flag_vol==1))//没赚15点,破1-3或更早的通路出1-S，之后下来在下沿出一半
        {
           if(ObjectGetString(0,"escapeS",OBJPROP_TEXT,0)=="0")
           {
              for(i=0;i<tlines_U;i++)
              {
                  if((LineShow_U[i][1]<point3_pos)&&(Low_M1[LineShow_U[i][1]]<point3))
                  break;
              }
              if(i<tlines_U)dis=LineShow_U[i][0]-LineShow_U[i][1];
              else dis=0;
              if(dis!=0)
              {
                 div=Low_M1[LineShow_U[i][0]]-Low_M1[LineShow_U[i][1]];
                 breakP1=div*(barsnum_M1-1-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                 breakP3=div*(barsnum_M1-3-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                 breakP4=div*(barsnum_M1-4-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                 if(nowp<breakP1-50*d_point)
                 {
                    escape1_pos=iHighest(High_M1,barsnum_M1-point1_pos,barsnum_M1-1);
                    escape1_=DoubleToString(High_M1[escape1_pos],8);
                    ObjectSetString(0,"escapeS",OBJPROP_TEXT,"1");
                    ObjectCreate(0,"escapeSt",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                    ObjectSetString(0,"escape1",OBJPROP_TEXT,escape1_);
                    ObjectCreate(0,"escape1t",OBJ_ARROW_THUMB_UP,0,Time_M1[escape1_pos],High_M1[escape1_pos]);
                    time1_=TimeToString(Time_M5[barsnum_M5-1]);
                    ObjectSetString(0,"estime_po",OBJPROP_TEXT,time1_);
                    return;
                 }
                 if(Low_M1[barsnum_M1-3]<breakP3-5*d_point)
                 {
                    if((nowp<Low_M1[barsnum_M1-2]-5*d_point)&&(Low_M1[barsnum_M1-2]<Low_M1[barsnum_M1-3])&&(Low_M1[barsnum_M1-4]>=breakP4))
                    {
                       escape1_pos=iHighest(High_M1,barsnum_M1-point1_pos,barsnum_M1-1);
                       escape1_=DoubleToString(High_M1[escape1_pos],8);
                       ObjectSetString(0,"escapeS",OBJPROP_TEXT,"1");
                       ObjectCreate(0,"escapeSt",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                       ObjectSetString(0,"escape1",OBJPROP_TEXT,escape1_);
                       ObjectCreate(0,"escape1t",OBJ_ARROW_THUMB_UP,0,Time_M1[escape1_pos],High_M1[escape1_pos]);
                       time1_=TimeToString(Time_M5[barsnum_M5-1]);
                       ObjectSetString(0,"estime_po",OBJPROP_TEXT,time1_);
                       return;
                    }
                 }
              }
           }
           else
           {
               escape1=StringToDouble(ObjectGetString(0,"escape1",OBJPROP_TEXT,0));
               time1=StringToTime(ObjectGetString(0,"estime_po",OBJPROP_TEXT,0));
               if(nowp>escape1)
               {
                  ObjectDelete(0,"escapeS");
                  ObjectDelete(0,"escapeSt");
                  ObjectDelete(0,"escape1");
                  ObjectDelete(0,"escape1t");
                  ObjectDelete(0,"estime_po");
                  return;
               }
               for(i=0;i<tlines_D;i++)
               {
                   if((Time_M1[LineShow_D[i][1]]<time1)&&(High_M1[LineShow_D[i][1]]>escape1-(escape1-nowp)/3))
                   {
                      flag_escape1_3=1;
                      break;
                   }
               }
               if(flag_escape1_3==1)
               {
                  dis=LineShow_D[i][0]-LineShow_D[i][1];
                  if(dis!=0)
                  {
                     div=High_M1[LineShow_D[i][0]]-High_M1[LineShow_D[i][1]];
                     breakP1=div*(barsnum_M1-1-LineShow_D[i][0])/dis+High_M1[LineShow_D[i][0]];
                     kuan=div*(LineShow_D[i][2]-LineShow_D[i][0])/dis+High_M1[LineShow_D[i][0]]-Low_M1[LineShow_D[i][2]];
                     if(nowp>breakP1-kuan/10)
                     {
                        fsell(0,vol_full/2);
                        closeby_buy();
                        Alert("没赚15点出一半");
                        ObjectDelete(0,"escapeS");
                        ObjectDelete(0,"escapeSt");
                        ObjectDelete(0,"escape1");
                        ObjectDelete(0,"escape1t");
                        ObjectDelete(0,"estime_po");
                        return;
                     }
                  }
               }
           }
        }
        if((ObjectGetString(0,"escape_mode",OBJPROP_TEXT,0)=="1")&&(flag_vol==1))//赚15点，破3-4出一半
        {
            for(i=0;i<tlines_U;i++)
            {
                if((LineShow_U[i][1]<point3_pos)||(Low_M1[LineShow_U[i][1]]<point3+(nowp-point3)/3))
                break;
            }
            if(i<tlines_U)dis=LineShow_U[i][0]-LineShow_U[i][1];
            else dis=0;
            if(dis!=0)
            {
               div=Low_M1[LineShow_U[i][0]]-Low_M1[LineShow_U[i][1]];
               breakP1=div*(barsnum_M1-1-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
               breakP3=div*(barsnum_M1-3-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
               breakP4=div*(barsnum_M1-4-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
               if(nowp<breakP1-50*d_point)
               {
                  fsell(0,vol_full/2);
                  closeby_buy();
                  Alert("赚15点，破3-4出一半");
                  return;
               }
               if(Low_M1[barsnum_M1-3]<breakP3-5*d_point)
               {
                  if((nowp<Low_M1[barsnum_M1-2]-5*d_point)&&(Low_M1[barsnum_M1-2]<Low_M1[barsnum_M1-3])&&(Low_M1[barsnum_M1-4]>=breakP4))
                  {
                      fsell(0,vol_full/2);
                      closeby_buy();
                      Alert("赚15点，破3-4出一半");
                      return; 
                  }
               }
           }
        }
        if((flag_vol==1)&&(ObjectGetString(0,"escape_mode",OBJPROP_TEXT,0)=="2"))//25点以上
        {
           if(profit>vol_full*500)
           {
              SL=PositionGetDouble(POSITION_PRICE_OPEN);
              if(sl>SL)trade.PositionModify(_Symbol,SL,0);
           }
           if(ObjectGetString(0,"escapeS",OBJPROP_TEXT,0)!="2")//破通道出1和S
           {
              for(i=0;i<tlines_U-1;i++)
              {
                  dis=LineShow_U[i][0]-LineShow_U[i][1];
                  if(dis!=0)
                  {
                     div=Low_M1[LineShow_U[i][0]]-Low_M1[LineShow_U[i][1]];
                     breakP1=div*(barsnum_M1-1-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                     dis=LineShow_U[i+1][0]-LineShow_U[i+1][1];
                     if(dis!=0)
                     {
                        div=Low_M1[LineShow_U[i+1][0]]-Low_M1[LineShow_U[i+1][1]];
                        breakP11=div*(barsnum_M1-1-LineShow_U[i+1][0])/dis+Low_M1[LineShow_U[i+1][0]];
                        if(breakP1-breakP11>200*d_point)break;
                     }
                     else break;
                  }
              }
              if(i<tlines_U)dis=LineShow_U[i][0]-LineShow_U[i][1];
              else dis=0;
              if(dis!=0)
              {
                 div=Low_M1[LineShow_U[i][0]]-Low_M1[LineShow_U[i][1]];
                 breakP1=div*(barsnum_M1-1-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                 breakP3=div*(barsnum_M1-3-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                 breakP4=div*(barsnum_M1-4-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                 if(nowp<breakP1-50*d_point)
                 {
                    ObjectSetString(0,"escapeS",OBJPROP_TEXT,"2");
                    if(ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]]<ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]])
                    {
                       zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
                       time1=Time_M5[ZigZagBuffer_pos_M5[2]];
                    }
                    else
                    {
                        zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
                        time1=Time_M5[ZigZagBuffer_pos_M5[1]];
                    }
                    escape1_=DoubleToString(zig1,8);
                    ObjectCreate(0,"escapeSt",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                    ObjectSetString(0,"escape1",OBJPROP_TEXT,escape1_);
                    ObjectCreate(0,"escape1t",OBJ_ARROW_THUMB_UP,0,time1,zig1);
                    time1_=TimeToString(Time_M5[barsnum_M5-1]);
                    ObjectSetString(0,"estime_po",OBJPROP_TEXT,time1_);
                    return;
                 }
                 if(Low_M1[barsnum_M1-3]<breakP3-5*d_point)
                 {
                    if((nowp<Low_M1[barsnum_M1-2]-5*d_point)&&(Low_M1[barsnum_M1-2]<Low_M1[barsnum_M1-3])&&(Low_M1[barsnum_M1-4]>=breakP4))
                    {
                       ObjectSetString(0,"escapeS",OBJPROP_TEXT,"2");
                       if(ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]]<ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]])
                       {
                          zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
                          time1=Time_M5[ZigZagBuffer_pos_M5[2]];
                       }
                       else
                       {
                           zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
                           time1=Time_M5[ZigZagBuffer_pos_M5[1]];
                       }
                       escape1_=DoubleToString(zig1,8);
                       ObjectCreate(0,"escapeSt",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                       ObjectSetString(0,"escape1",OBJPROP_TEXT,escape1_);
                       ObjectCreate(0,"escape1t",OBJ_ARROW_THUMB_UP,0,time1,zig1);
                       time1_=TimeToString(Time_M5[barsnum_M5-1]);
                       ObjectSetString(0,"estime_po",OBJPROP_TEXT,time1_);
                       return;
                    }
                 }
              }
           }
           if(ObjectGetString(0,"escapeS",OBJPROP_TEXT,0)=="1")
           {
              ObjectDelete(0,"escapeS");
              ObjectDelete(0,"escapeSt");
              ObjectDelete(0,"estime_po");
              ObjectDelete(0,"escape1");
              ObjectDelete(0,"escape1t");
              ObjectDelete(0,"escape2");
              ObjectDelete(0,"escape2t");
              return;
           }
           if(ObjectGetString(0,"escapeS",OBJPROP_TEXT,0)=="2")
           {
              if(ObjectGetString(0,"escape2",OBJPROP_TEXT,0)=="0")
              {
                 escape1=StringToDouble(ObjectGetString(0,"escape1",OBJPROP_TEXT,0));
                 time1=StringToTime(ObjectGetString(0,"estime_po",OBJPROP_TEXT,0));
                 if(nowp>escape1)
                 {
                    ObjectSetString(0,"escape2",OBJPROP_TEXT,"A");//代表打破1点
                    return;
                 }
                 zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
                 zig2=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
                 time2=Time_M5[ZigZagBuffer_pos_M5[2]];
                 if((zig1>zig2)&&(time2>=time1))
                 {
                    escape2_=DoubleToString(zig2,8);
                    ObjectSetString(0,"escape2",OBJPROP_TEXT,escape2_);
                    ObjectCreate(0,"escape2t",OBJ_ARROW_THUMB_UP,0,time2,zig2);
                    return;
                 }
             }
             else
             {
                 if(ObjectGetString(0,"escape2",OBJPROP_TEXT,0)=="A")//破最小的通道出
                 {
                    if(ObjectGetString(0,"beforeS_2",OBJPROP_TEXT,0)=="0")
                    {
                       i=0;
                       if(i<tlines_U)dis=LineShow_U[i][0]-LineShow_U[i][1];
                       else dis=0;
                       if(dis!=0)
                       {
                          div=Low_M1[LineShow_U[i][0]]-Low_M1[LineShow_U[i][1]];
                          breakP1=div*(barsnum_M1-1-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                          breakP3=div*(barsnum_M1-3-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                          breakP4=div*(barsnum_M1-4-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                          if(nowp<breakP1-50*d_point)
                          {
                             timeS_2_=TimeToString(Time_M5[barsnum_M5-1]);
                             escape1_2=High_M1[iHighest(High_M1,barsnum_M1-LineShow_U[i][1],barsnum_M1-1)];
                             escape1_2_=DoubleToString(escape1_2,8);
                             ObjectSetString(0,"beforeS_2",OBJPROP_TEXT,timeS_2_);
                             ObjectSetString(0,"escape1_2",OBJPROP_TEXT,escape1_2_);
                             ObjectCreate(0,"escapeS_2t",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                             return;
                          }
                          if(Low_M1[barsnum_M1-3]<breakP3-5*d_point)
                          {
                             if((nowp<Low_M1[barsnum_M1-2]-5*d_point)&&(Low_M1[barsnum_M1-2]<Low_M1[barsnum_M1-3])&&(Low_M1[barsnum_M1-4]>=breakP4))
                             {
                                timeS_2_=TimeToString(Time_M5[barsnum_M5-1]);
                                escape1_2=High_M1[iHighest(High_M1,barsnum_M1-LineShow_U[i][1],barsnum_M1-1)];
                                escape1_2_=DoubleToString(escape1_2,8);
                                ObjectSetString(0,"beforeS_2",OBJPROP_TEXT,timeS_2_);
                                ObjectSetString(0,"escape1_2",OBJPROP_TEXT,escape1_2_);
                                ObjectCreate(0,"escapeS_2t",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                                return;
                             }
                          }
                       }
                    }
                    else
                    {
                        escape1_2=StringToDouble(ObjectGetString(0,"escape1_2",OBJPROP_TEXT,0));
                        if(nowp>escape1_2)
                        {
                           ObjectDelete(0,"beforeS_2");
                           ObjectDelete(0,"escape1_2");
                           ObjectDelete(0,"escapeS_2t");
                           ObjectDelete(0,"escape2_2");
                           ObjectDelete(0,"escape2_2t");
                           return;
                        }
                        if(ObjectGetString(0,"escape2_2",OBJPROP_TEXT,0)=="0")
                        {
                           escape2_2_=DoubleToString(nowp,8);
                           ObjectSetString(0,"escape2_2",OBJPROP_TEXT,escape2_2_);
                           ObjectCreate(0,"escape2_2t",OBJ_ARROW_THUMB_UP,0,Time_M5[barsnum_M5-1],nowp);
                           return;
                        }
                        else
                        {
                           escape2_2=StringToDouble(ObjectGetString(0,"escape2_2",OBJPROP_TEXT,0));
                           timeS_2=StringToTime(ObjectGetString(0,"beforeS_2",OBJPROP_TEXT,0));
                           if(Time_M5[barsnum_M5-2]>timeS_2)
                           {
                              if(Low_M5[barsnum_M5-2]<escape2_2)
                              {
                                 escape2_2_=DoubleToString(Low_M5[barsnum_M5-2],8);
                                 ObjectSetString(0,"escape2_2",OBJPROP_TEXT,escape2_2_);
                                 ObjectSetDouble(0,"escape2_2t",OBJPROP_PRICE,Low_M5[barsnum_M5-2]);
                                 ObjectSetInteger(0,"escape2_2t",OBJPROP_TIME,Time_M5[barsnum_M5-2]);
                                 return;
                              }
                              if((Low_M5[barsnum_M5-2]>=escape2_2)&&(nowp<escape2_2))
                              {
                                 fsell(0,vol_full/2);
                                 closeby_buy();
                                 ObjectDelete(0,"escape_mode");
                                 ObjectDelete(0,"escapeS");
                                 ObjectDelete(0,"escapeSt");
                                 ObjectDelete(0,"estime_po");
                                 ObjectDelete(0,"escape1");
                                 ObjectDelete(0,"escape1t");
                                 ObjectDelete(0,"escape2");
                                 ObjectDelete(0,"escape2t");
                                 ObjectDelete(0,"beforeS_2");
                                 ObjectDelete(0,"escape1_2");
                                 ObjectDelete(0,"escapeS_2t");
                                 ObjectDelete(0,"escape2_2");
                                 ObjectDelete(0,"escape2_2t");
                                 Alert("25点以上左侧+123出场");
                                 return;
                              }
                           }
                        }
                    }
                 }
                 else//等下来以后破最小的通道出
                 {
                     escape1=StringToDouble(ObjectGetString(0,"escape1",OBJPROP_TEXT,0));
                     time1=StringToTime(ObjectGetString(0,"estime_po",OBJPROP_TEXT,0));
                     if(nowp>escape1)
                     {
                        ObjectSetString(0,"escape2",OBJPROP_TEXT,"A");//代表打破1点
                        return;
                     }
                     escape2=StringToDouble(ObjectGetString(0,"escape2",OBJPROP_TEXT,0));
                     zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
                     zig2=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
                     time2=Time_M5[ZigZagBuffer_pos_M5[2]];
                     escape2_time=ObjectGetInteger(0,"escape2t",OBJPROP_TIME,0);
                     if((zig1<zig2)&&(time2>=escape2_time))
                     {
                        close_buy();
                        Alert("25点以上，123全出");
                        ObjectsDeleteAll(0,0,OBJ_ARROW_THUMB_UP);
                        ObjectsDeleteAll(0,0,OBJ_LABEL);
                        return;
                     }
                  }
              }
           }
        }
     }
     if((ObjectGetString(0,"escape_ag",OBJPROP_TEXT,0)!="0")&&(flag_vol==1))//接过单,破接单之前的通道123出一半，(或者破外面的通道直接全出)
     {
         price_ag=StringToDouble(ObjectGetString(0,"price_ag",OBJPROP_TEXT,0));
         time_ag=StringToTime(ObjectGetString(0,"escape_ag",OBJPROP_TEXT,0));
         if(ObjectGetString(0,"escape_mode",OBJPROP_TEXT,0)!="2")
         {
            if(nowp-price_ag>=250*d_point)ObjectSetString(0,"escape_mode",OBJPROP_TEXT,"2");
            else ObjectSetString(0,"escape_mode",OBJPROP_TEXT,"1");
         }
         if(ObjectGetString(0,"escape_mode",OBJPROP_TEXT,0)=="0")
         {
            i=0;
            if(i<tlines_U)dis=LineShow_U[i][0]-LineShow_U[i][1];
            else dis=0;
            if(dis!=0)
            {
               div=Low_M1[LineShow_U[i][0]]-Low_M1[LineShow_U[i][1]];
               breakP1=div*(barsnum_M1-1-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
               breakP3=div*(barsnum_M1-3-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
               breakP4=div*(barsnum_M1-4-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
               if(nowp<breakP1-70*d_point)
               {
                  fsell(0,vol_full/2);
                  closeby_buy();
                  Alert("接单后亏损，破最小通路出一半");
                  return;
               }
               if(Low_M1[barsnum_M1-3]<breakP3-5*d_point)
               {
                  if((nowp<Low_M1[barsnum_M1-2]-5*d_point)&&(Low_M1[barsnum_M1-2]<Low_M1[barsnum_M1-3])&&(Low_M1[barsnum_M1-4]>=breakP4))
                  {
                     fsell(0,vol_full/2);
                     closeby_buy();
                     Alert("接单后亏损，破最小通路出一半");
                     return; 
                  }
               }
            }
         }
         if(ObjectGetString(0,"escape_mode",OBJPROP_TEXT,0)=="1")
         {
            for(i=0;i<tlines_U;i++)
            {
                if((LineShow_U[i][1]<point3_pos)||(Low_M1[LineShow_U[i][1]]<point3+(nowp-point3)/3))
                break;
            }
            if(i<tlines_U)dis=LineShow_U[i][0]-LineShow_U[i][1];
            else dis=0;
            if(dis!=0)
            {
               div=Low_M1[LineShow_U[i][0]]-Low_M1[LineShow_U[i][1]];
               breakP1=div*(barsnum_M1-1-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
               breakP3=div*(barsnum_M1-3-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
               breakP4=div*(barsnum_M1-4-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
               if(nowp<breakP1-50*d_point)
               {
                  fsell(0,vol_full/2);
                  closeby_buy();
                  Alert("接单后，破3-4出一半");
                  return;
               }
               if(Low_M1[barsnum_M1-3]<breakP3-5*d_point)
               {
                  if((nowp<Low_M1[barsnum_M1-2]-5*d_point)&&(Low_M1[barsnum_M1-2]<Low_M1[barsnum_M1-3])&&(Low_M1[barsnum_M1-4]>=breakP4))
                  {
                     fsell(0,vol_full/2);
                     closeby_buy();
                     Alert("接单后，破3-4出一半");
                     return; 
                  }
               }
            }
         }
         if(ObjectGetString(0,"escape_mode",OBJPROP_TEXT,0)=="2")
         {
            if(ObjectGetString(0,"escape",OBJPROP_TEXT,0)=="0")
            {
               time_ag=StringToTime(ObjectGetString(0,"escape_ag",OBJPROP_TEXT,0));
               for(i=0;i<tlines_U;i++)
               {
                   if(Time_M1[LineShow_U[i][1]]<time_ag)break;
               }
               if((middle_TL>0)&&(middle_TL-1<i))i=middle_TL-1;
               if(i<tlines_U)dis=LineShow_U[i][0]-LineShow_U[i][1];
               else dis=0;
               if(dis!=0)
               {
                  div=Low_M1[LineShow_U[i][0]]-Low_M1[LineShow_U[i][1]];
                  breakP1=div*(barsnum_M1-1-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                  breakP3=div*(barsnum_M1-3-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                  breakP4=div*(barsnum_M1-4-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                  if(nowp<breakP1-50*d_point)
                  {
                     ObjectSetString(0,"escape",OBJPROP_TEXT,"1");
                     if(i==middle_TL-1)
                        ObjectSetString(0,"escape",OBJPROP_TEXT,"2");
                     escapeS_=DoubleToString(breakP1,8);
                     ObjectSetString(0,"escapeS",OBJPROP_TEXT,escapeS_);
                     if(ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]]<ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]])
                     {
                        zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
                        time1=Time_M5[ZigZagBuffer_pos_M5[2]];
                     }
                     else
                     {
                         zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
                         time1=Time_M5[ZigZagBuffer_pos_M5[1]];
                     }
                     escape1_=DoubleToString(zig1,8);
                     ObjectCreate(0,"escapeSt",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                     ObjectSetString(0,"escape1",OBJPROP_TEXT,escape1_);
                     ObjectCreate(0,"escape1t",OBJ_ARROW_THUMB_UP,0,time1,zig1);
                     time1_=TimeToString(Time_M5[barsnum_M5-1]);
                     ObjectSetString(0,"estime_po",OBJPROP_TEXT,time1_);
                     return;
                  }
                  if(Low_M1[barsnum_M1-3]<breakP3-5*d_point)
                  {
                     if((nowp<Low_M1[barsnum_M1-2]-5*d_point)&&(Low_M1[barsnum_M1-2]<Low_M1[barsnum_M1-3])&&(Low_M1[barsnum_M1-4]>=breakP4))
                     {
                        ObjectSetString(0,"escape",OBJPROP_TEXT,"1");
                        if(i==middle_TL-1)
                           ObjectSetString(0,"escape",OBJPROP_TEXT,"2");
                        escapeS_=DoubleToString(breakP1,8);
                        ObjectSetString(0,"escapeS",OBJPROP_TEXT,escapeS_);
                        if(ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]]<ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]])
                        {
                           zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
                           time1=Time_M5[ZigZagBuffer_pos_M5[2]];
                        }
                        else
                        {
                            zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
                            time1=Time_M5[ZigZagBuffer_pos_M5[1]];
                        }
                        escape1_=DoubleToString(zig1,8);
                        ObjectCreate(0,"escapeSt",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                        ObjectSetString(0,"escape1",OBJPROP_TEXT,escape1_);
                        ObjectCreate(0,"escape1t",OBJ_ARROW_THUMB_UP,0,time1,zig1);
                        time1_=TimeToString(Time_M5[barsnum_M5-1]);
                        ObjectSetString(0,"estime_po",OBJPROP_TEXT,time1_);
                        return;
                    }
                  }
               }
            }
            else
            {
                escapeS=StringToDouble(ObjectGetString(0,"escapeS",OBJPROP_TEXT,0));
                escape1=StringToDouble(ObjectGetString(0,"escape1",OBJPROP_TEXT,0));
                estime=StringToTime(ObjectGetString(0,"estime_po",OBJPROP_TEXT,0));
                if(nowp>escape1)
                {
                   ObjectDelete(0,"escape");
                   ObjectDelete(0,"escapeS");
                   ObjectDelete(0,"escapeSt");
                   ObjectDelete(0,"estime_po");
                   ObjectDelete(0,"escape1");
                   ObjectDelete(0,"escape1t");
                   ObjectDelete(0,"escape2");
                   ObjectDelete(0,"escape2t");
                   ObjectDelete(0,"escapeS_2to3");
                   ObjectDelete(0,"escape1_2to3");
                   ObjectDelete(0,"escapeS_2to3t");
                   ObjectDelete(0,"escape2_2to3");
                   ObjectDelete(0,"escape2_2to3t");
                   return;
                }
                if(ObjectGetString(0,"escape2",OBJPROP_TEXT,0)=="0")
                {
                   zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
                   zig2=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
                   time2=Time_M5[ZigZagBuffer_pos_M5[2]];
                   if((zig1>zig2)&&(time2>=estime))
                   {
                     point2_=DoubleToString(zig2,8);
                     ObjectSetString(0,"escape2",OBJPROP_TEXT,point2_);
                     ObjectCreate(0,"escape2t",OBJ_ARROW_THUMB_UP,0,time2,zig2);
                     return;
                   }
                }
                else
                {
                    if(ObjectGetString(0,"escape",OBJPROP_TEXT,0)=="1")vol_now=vol_full/2;
                    if(ObjectGetString(0,"escape",OBJPROP_TEXT,0)=="2")vol_now=vol_full;
                    escape2=StringToDouble(ObjectGetString(0,"escape2",OBJPROP_TEXT,0));
                    zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
                    zig2=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
                    time3=Time_M5[ZigZagBuffer_pos_M5[2]+2];
                    int flag_2to3=0;
                    for(i=0;i<tlines_U;i++)
                    {
                        if((Time_M1[LineShow_U[i][1]]>estime)&&(Low_M1[LineShow_U[i][1]]<escape2+(nowp-escape2)/3))
                        {
                           flag_2to3=1; 
                           break;
                        }
                    }
                    if(ObjectGetString(0,"escapeS_2to3",OBJPROP_TEXT,0)=="0")
                    {
                       if((flag_2to3==1)&&(i<tlines_U))
                       {
                          dis=LineShow_U[i][0]-LineShow_U[i][1];
                          if(dis!=0)
                          {
                             div=Low_M1[LineShow_U[i][0]]-Low_M1[LineShow_U[i][1]];
                             breakP1=div*(barsnum_M1-1-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                             breakP3=div*(barsnum_M1-3-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                             breakP4=div*(barsnum_M1-4-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                          }
                          if(nowp<breakP1-50*d_point)
                          {
                             timeS_2to3_=TimeToString(Time_M5[barsnum_M5-1]);
                             escape1_2to3=High_M1[iHighest(High_M1,barsnum_M1-LineShow_U[i][1],barsnum_M1-1)];
                             escape1_2to3_=DoubleToString(escape1_2to3,8);
                             ObjectSetString(0,"escapeS_2to3",OBJPROP_TEXT,timeS_2to3_);
                             ObjectSetString(0,"escape1_2to3",OBJPROP_TEXT,escape1_2to3_);
                             ObjectCreate(0,"escapeS_2to3t",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                             return;
                          }
                          if(Low_M1[barsnum_M1-3]<breakP3-5*d_point)
                          {
                             if((nowp<Low_M1[barsnum_M1-2]-5*d_point)&&(Low_M1[barsnum_M1-2]<Low_M1[barsnum_M1-3])&&(Low_M1[barsnum_M1-4]>=breakP4))
                             {
                                  timeS_2to3_=TimeToString(Time_M5[barsnum_M5-1]);
                                  escape1_2to3=High_M1[iHighest(High_M1,barsnum_M1-LineShow_U[i][1],barsnum_M1-1)];
                                  escape1_2to3_=DoubleToString(escape1_2to3,8);
                                  ObjectSetString(0,"escapeS_2to3",OBJPROP_TEXT,timeS_2to3_);
                                  ObjectSetString(0,"escape1_2to3",OBJPROP_TEXT,escape1_2to3_);
                                  ObjectCreate(0,"escapeS_2to3t",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                                  return;
                              }
                          }
                       }
                    }
                    else
                    {
                        escape1_2to3=StringToDouble(ObjectGetString(0,"escape1_2to3",OBJPROP_TEXT,0));
                        if(nowp>escape1_2to3)
                        {
                           ObjectDelete(0,"escapeS_2to3");
                           ObjectDelete(0,"escape1_2to3");
                           ObjectDelete(0,"escapeS_2to3t");
                           ObjectDelete(0,"escape2_2to3");
                           ObjectDelete(0,"escape2_2to3t");
                           return;
                        }
                        if(ObjectGetString(0,"escape2_2to3",OBJPROP_TEXT,0)=="0")
                        {
                           escape2_2to3_=DoubleToString(nowp,8);
                           ObjectSetString(0,"escape2_2to3",OBJPROP_TEXT,escape2_2to3_);
                           ObjectCreate(0,"escape2_2to3t",OBJ_ARROW_THUMB_UP,0,Time_M5[barsnum_M5-1],nowp);
                           return;
                        }
                       else
                       {
                            escape2_2to3=StringToDouble(ObjectGetString(0,"escape2_2to3",OBJPROP_TEXT,0));
                            timeS_2to3=StringToTime(ObjectGetString(0,"escapeS_2to3",OBJPROP_TEXT,0));
                            if(Time_M5[barsnum_M5-2]>timeS_2to3)
                            {
                               if(Low_M5[barsnum_M5-2]<escape2_2to3)
                               {
                                  escape2_2to3_=DoubleToString(Low_M5[barsnum_M5-2],8);
                                  ObjectSetString(0,"escape2_2to3",OBJPROP_TEXT,escape2_2to3_);
                                  ObjectSetDouble(0,"escape2_2to3t",OBJPROP_PRICE,Low_M5[barsnum_M5-2]);
                                  ObjectSetInteger(0,"escape2_2to3t",OBJPROP_TIME,Time_M5[barsnum_M5-2]);
                                  return;
                               }
                               if((Low_M5[barsnum_M5-2]>=escape2_2to3)&&(nowp<escape2_2to3))
                               {
                                  close_buy();
                                  Alert("接单以后破中通道2次123全出");
                                  ObjectDelete(0,"escape");
                                  ObjectDelete(0,"escapeS");
                                  ObjectDelete(0,"escapeSt");
                                  ObjectDelete(0,"estime_po");
                                  ObjectDelete(0,"escape1");
                                  ObjectDelete(0,"escape1t");
                                  ObjectDelete(0,"escape2");
                                  ObjectDelete(0,"escape2t");
                                  ObjectDelete(0,"escapeS_2to3");
                                  ObjectDelete(0,"escapeS_2to3t");
                                  ObjectDelete(0,"escape2_2to3");
                                  ObjectDelete(0,"escape2_2to3t");
                                  return;
                               }
                            }
                        }
                    }
                    if((zig1<zig2)&&(time3>=estime)&&(nowp<escapeS))
                    {
                       closeby_buy();
                       Alert("接单以后破通道123全出，Z字线123");
                       ObjectDelete(0,"escape");
                       ObjectDelete(0,"escapeS");
                       ObjectDelete(0,"escapeSt");
                       ObjectDelete(0,"estime_po");
                       ObjectDelete(0,"escape1");
                       ObjectDelete(0,"escape1t");
                       ObjectDelete(0,"escape2");
                       ObjectDelete(0,"escape2t");
                       ObjectDelete(0,"escapeS_2to3");
                       ObjectDelete(0,"escapeS_2to3t");
                       ObjectDelete(0,"escape2_2to3");
                       ObjectDelete(0,"escape2_2to3t");
                       return;
                    }
                }
            }
        }
     }
     if(flag_vol==2)
     {
        i=barsnum_M1-1;
        while((Time_M1[i]>deal_time)&&(Time_M1[i]>Time_D1[barsnum_D1-10]))
        {
              i--;
        }
        int pointh_pos=iHighest(High_M1,barsnum_M1-i,barsnum_M1-5);
        double pointh=High_M1[pointh_pos];
        double pointl;
        if(ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]]<ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]])
           pointl=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
        else pointl=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
        if(nowp>pointh)
        {
           time_ag_=TimeToString(Time_M5[barsnum_M5-1]);
           ObjectSetString(0,"escape_ag",OBJPROP_TEXT,time_ag_);
           price_ag_=DoubleToString(pointl,8);
           ObjectSetString(0,"price_ag",OBJPROP_TEXT,price_ag_);
           fbuy(sl,vol_full/2);
           Alert("接一半");
           ObjectDelete(0,"escape_mode");
           ObjectDelete(0,"escapeS");
           ObjectDelete(0,"escapeSt");
           ObjectDelete(0,"estime_po");
           ObjectDelete(0,"escape1");
           ObjectDelete(0,"escape1t");
           ObjectDelete(0,"escape2");
           ObjectDelete(0,"escape2t");
           return;
        }
        if(ObjectGetString(0,"escape1_2to3",OBJPROP_TEXT,0)!="0")
        {
           escape1_2to3=StringToDouble(ObjectGetString(0,"escape1_2to3",OBJPROP_TEXT,0));
           if(nowp>escape1_2to3)
           {
              time_ag_=TimeToString(Time_M5[barsnum_M5-1]);
              ObjectSetString(0,"escape_ag",OBJPROP_TEXT,time_ag_);
              price_ag_=DoubleToString(pointl,8);
              ObjectSetString(0,"price_ag",OBJPROP_TEXT,price_ag_);
              fbuy(sl,vol_full/2);
              Alert("双123的接单");
              ObjectDelete(0,"escape_mode");
              ObjectDelete(0,"escapeS");
              ObjectDelete(0,"escapeSt");
              ObjectDelete(0,"estime_po");
              ObjectDelete(0,"escape1");
              ObjectDelete(0,"escape1t");
              ObjectDelete(0,"escape2");
              ObjectDelete(0,"escape2t");
              ObjectDelete(0,"escape1_2to3");
              return;
           }
        }
        if(ObjectGetString(0,"escapeS",OBJPROP_TEXT,0)=="0")
        {
           for(i=0;i<tlines_U-1;i++)
           {
               dis=LineShow_U[i][0]-LineShow_U[i][1];
               if(dis!=0)
               {
                  div=Low_M1[LineShow_U[i][0]]-Low_M1[LineShow_U[i][1]];
                  breakP1=div*(barsnum_M1-1-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                  dis=LineShow_U[i+1][0]-LineShow_U[i+1][1];
                  if(dis!=0)
                  {
                     div=Low_M1[LineShow_U[i+1][0]]-Low_M1[LineShow_U[i+1][1]];
                     breakP11=div*(barsnum_M1-1-LineShow_U[i+1][0])/dis+Low_M1[LineShow_U[i+1][0]];
                     if(breakP1-breakP11>200*d_point)break;
                  }
                  else break;
               }
           }
           if(big_TL>0)
           {
              datetime nowtime=SymbolInfoInteger(_Symbol,SYMBOL_TIME);//当前时间
              HistorySelect(Time_H4[barsnum_H4-60],nowtime);
              int order_num=HistoryOrdersTotal();//选择的历史区间内总交易次数
              int ticket=HistoryOrderGetTicket(order_num-1);//这是选择订单的ticket
              datetime last_deal_time=HistoryOrderGetInteger(ticket,ORDER_TIME_DONE);
              if(HistoryOrderGetInteger(ticket,ORDER_TYPE)==ORDER_TYPE_SELL)
              {
                 for(i=0;i<tlines_U;i++)
                 {
                     if(Time_M1[LineShow_U[i][1]]<last_deal_time)break;
                 }
              }
           }
           if(i<tlines_U)dis=LineShow_U[i][0]-LineShow_U[i][1];
           else dis=0;
           if(dis!=0)
           {
              div=Low_M1[LineShow_U[i][0]]-Low_M1[LineShow_U[i][1]];
              breakP1=div*(barsnum_M1-1-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
              breakP3=div*(barsnum_M1-3-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
              breakP4=div*(barsnum_M1-4-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
              if(nowp<breakP1-50*d_point)
              {
                 escapeS_=DoubleToString(breakP1,8);
                 ObjectSetString(0,"escapeS",OBJPROP_TEXT,escapeS_);
                 ObjectCreate(0,"escapeSt",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                 findperiod2();
                 return;
              }
              if(Low_M1[barsnum_M1-3]<breakP3-5*d_point)
              {
                 if((nowp<Low_M1[barsnum_M1-2]-5*d_point)&&(Low_M1[barsnum_M1-2]<Low_M1[barsnum_M1-3])&&(Low_M1[barsnum_M1-4]>=breakP4))
                 {
                    escapeS_=DoubleToString(breakP1,8);
                    ObjectSetString(0,"escapeS",OBJPROP_TEXT,escapeS_);
                    ObjectCreate(0,"escapeSt",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                    findperiod2();
                    return;
                 }
              }
           }
        }
        else
        {
            escapeS=StringToDouble(ObjectGetString(0,"escapeS",OBJPROP_TEXT,0));
            escape1=StringToDouble(ObjectGetString(0,"escape1",OBJPROP_TEXT,0));
            estime=StringToTime(ObjectGetString(0,"estime_po",OBJPROP_TEXT,0));
            period=StringToInteger(ObjectGetString(0,"trade_period",OBJPROP_TEXT,0));
            if((nowp<escapeS-(escape1-escapeS)/3*2)&&(escape1-escapeS>200*d_point)&&(big_TL<0))
            {
               close_buy();
               Alert("2/3出剩下一半");
               ObjectsDeleteAll(0,0,OBJ_ARROW_THUMB_UP);
               ObjectsDeleteAll(0,0,OBJ_LABEL);
               return;
            }
            if(ObjectGetString(0,"escape2",OBJPROP_TEXT,0)=="0")
            {
               if(nowp>escape1)
               {
                  ObjectDelete(0,"escape1");
                  ObjectDelete(0,"escape1t");
                  ObjectDelete(0,"escapeS");
                  ObjectDelete(0,"escapeSt");
                  return;
               }
               if(period==2)
               {
                  zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
                  zig2=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
                  time2=Time_M5[ZigZagBuffer_pos_M5[2]];
               }
               if(period==3)
               {
                  zig1=ZigZagBuffer_M15[ZigZagBuffer_pos_M15[1]];
                  zig2=ZigZagBuffer_M15[ZigZagBuffer_pos_M15[2]];
                  time2=Time_M15[ZigZagBuffer_pos_M15[2]];
               }
               if((zig1>zig2)&&(time2>=estime))
               {
                  point2_=DoubleToString(zig2,8);
                  ObjectSetString(0,"escape2",OBJPROP_TEXT,point2_);
                  ObjectCreate(0,"escape2t",OBJ_ARROW_THUMB_UP,0,time2,zig2);
                  return;
               }
            }
            else
            {
                if(nowp>escape1)
                {
                   ObjectDelete(0,"escape1");
                   ObjectDelete(0,"escape1t");
                   ObjectDelete(0,"escapeS");
                   ObjectDelete(0,"escapeSt");
                   ObjectDelete(0,"escape2");
                   ObjectDelete(0,"escape2t");
                   return;
                }
                escape2=StringToDouble(ObjectGetString(0,"escape2",OBJPROP_TEXT,0));
                zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
                zig2=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
                time3=Time_M5[ZigZagBuffer_pos_M5[2]+2];
                int flag_2to3=0;
                for(i=0;i<tlines_U;i++)
                {
                    if((Time_M1[LineShow_U[i][1]]>estime)&&(Low_M1[LineShow_U[i][1]]<escape2+(nowp-escape2)/3))
                    {
                       flag_2to3=1; 
                       break;
                    }
                }
                if((flag_2to3==1)&&(i<tlines_D))
                {
                   dis=LineShow_U[i][0]-LineShow_U[i][1];
                   if(dis!=0)
                   {
                      div=Low_M1[LineShow_U[i][0]]-Low_M1[LineShow_U[i][1]];
                      breakP1=div*(barsnum_M1-1-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                      breakP3=div*(barsnum_M1-3-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                      breakP4=div*(barsnum_M1-4-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                      if(nowp<breakP1-50*d_point)
                      {
                         close_buy();
                         Alert("123出剩下一半");
                         ObjectsDeleteAll(0,0,OBJ_ARROW_THUMB_UP);
                         ObjectsDeleteAll(0,0,OBJ_LABEL);
                         return;
                      }
                      if(Low_M1[barsnum_M1-3]<breakP3-5*d_point)
                      {
                         if((nowp<Low_M1[barsnum_M1-2]-5*d_point)&&(Low_M1[barsnum_M1-2]<Low_M1[barsnum_M1-3])&&(Low_M1[barsnum_M1-4]>=breakP4))
                         {
                              close_buy();
                              Alert("123出剩下一半");
                              ObjectsDeleteAll(0,0,OBJ_ARROW_THUMB_UP);
                              ObjectsDeleteAll(0,0,OBJ_LABEL);
                              return;
                          }
                      }
                   }
                }
                if((zig1<zig2)&&(time3>=estime)&&(nowp<escapeS))
                {
                   close_buy();
                   Alert("123出剩下一半");
                   ObjectsDeleteAll(0,0,OBJ_ARROW_THUMB_UP);
                   ObjectsDeleteAll(0,0,OBJ_LABEL);
                   return;
                }
            }
        }
     }
}

void escapeB2()
{
     double vol_full=0.42;
     if(yuanyou==true)vol_full=4.2;
     double point1,point2,point3;
     string point1_,point2_,point3_;
     datetime point1_po;
     string point1_po_;
     int point1_pos=0,point3_pos=0;
     string point1_pos_,point3_pos_;
     point1=StringToDouble(ObjectGetString(0,"point1",OBJPROP_TEXT,0));
     point2=StringToDouble(ObjectGetString(0,"point2",OBJPROP_TEXT,0));
     point3=StringToDouble(ObjectGetString(0,"point3",OBJPROP_TEXT,0));
     datetime point1_time=ObjectGetInteger(0,"point1t",OBJPROP_TIME,0);
     datetime deal_time=StringToTime(ObjectGetString(0,"deal_time",OBJPROP_TEXT,0));
     double nowp=SymbolInfoDouble(_Symbol,SYMBOL_BID);
     double vol=PositionGetDouble(POSITION_VOLUME);
     double profit=PositionGetDouble(POSITION_PROFIT);
     double sl=PositionGetDouble(POSITION_SL);
     double deal_price=PositionGetDouble(POSITION_PRICE_OPEN);
     string deal_price_;
     double kuan;
     double SL;
     double escapeS;
     string escapeS_;
     int i,dis;
     double div,breakP1,breakP3,breakP4,breakP11;
     double escape1,escape2;
     string escape1_,escape2_;
     datetime point2_time,escape2_time;
     datetime estime;
     int period;
     double zig1,zig2;
     datetime time1,time2,time3,time_po;
     string time1_,time2_;
     int escape1_pos;
     int flag_escape1_3=0;
     datetime timeS_2;
     double escape1_2,escape2_2;
     string escape1_2_,escape2_2_,timeS_2_;
     datetime time_ag;
     string time_ag_;
     datetime timeS_2to3;
     double escape1_2to3,escape2_2to3;
     string timeS_2to3_,escape1_2to3_,escape2_2to3_;
     double price_ag;
     string price_ag_;
     int position_num=PositionsTotal();
     ulong position_ticket;
     int position_i=position_num;
     int position_sell_num=0;
     while(position_i>0)
     {
        position_ticket=PositionGetTicket(position_i-1);//这是仓位的ticket
        positioninfo.SelectByTicket(position_ticket);
        if((positioninfo.Symbol()==_Symbol)&&(positioninfo.PositionType()==POSITION_TYPE_BUY))
        {
            position_sell_num++;
        }
        position_i--;
     }
     int flag_vol=0;
     if((position_sell_num>1)||(vol==vol_full))
     {
         flag_vol=1;
     }
     if((position_sell_num==1)&&(vol==vol_full/2))
     {
         flag_vol=2;
     }
     if((flag_vol==1)&&(ObjectGetString(0,"escape_ag",OBJPROP_TEXT,0)=="0"))//赚了15个点
     {
        if(ObjectGetString(0,"deal_price",OBJPROP_TEXT,0)=="0")
        {
           deal_price_=DoubleToString(deal_price,8);
           ObjectSetString(0,"deal_price",OBJPROP_TEXT,deal_price_);
        }
        if(ObjectGetString(0,"escape_mode",OBJPROP_TEXT,0)=="0")
        {
           if(profit>=vol_full*150)
           {
              ObjectSetString(0,"escape_mode",OBJPROP_TEXT,"1");
           }
        }
        if(ObjectGetString(0,"escape_mode",OBJPROP_TEXT,0)=="1")
        {
           if(profit>=vol_full*250)
           {
              ObjectSetString(0,"escape_mode",OBJPROP_TEXT,"2");
           }
        }
     }
     /*if(ObjectGetString(0,"escape_ag",OBJPROP_TEXT,0)!="0")
     {
        deal_price=StringToDouble(ObjectGetString(0,"deal_price",OBJPROP_TEXT,0));
        if((nowp<deal_price-0.30)&&(deal_price!=0))
        {
           ObjectSetString(0,"escape_mode",OBJPROP_TEXT,"2");
        }
     }*/
     if(ObjectGetString(0,"point3",OBJPROP_TEXT,0)!="0")//如果有2点、3点
     {
        for(i=barsnum_M1-1;i>barsnum_M1-50000;i--)
        {
            if((Low_M1[i]<=point3)&&(point3_pos==0))point3_pos=i;
            if((Low_M1[i]<=point1)&&(point1_pos==0))
            {
               point1_pos=i;
               break;
            }
        }
     }
     if(ObjectGetString(0,"escape_ag",OBJPROP_TEXT,0)=="0")//没接过单
     {
        if((ObjectGetString(0,"escape_mode",OBJPROP_TEXT,0)=="0")&&(flag_vol==1))//没赚15点,破1-3或更早的通路出1-S，之后下来在下沿出一半
        {
           if(ObjectGetString(0,"escapeS",OBJPROP_TEXT,0)=="0")
           {
              for(i=0;i<tlines_U;i++)
              {
                  if((LineShow_U[i][1]<point3_pos)&&(Low_M1[LineShow_U[i][1]]<point3))
                  break;
              }
              if(i<tlines_U)dis=LineShow_U[i][0]-LineShow_U[i][1];
              else dis=0;
              if(dis!=0)
              {
                 div=Low_M1[LineShow_U[i][0]]-Low_M1[LineShow_U[i][1]];
                 breakP1=div*(barsnum_M1-1-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                 breakP3=div*(barsnum_M1-3-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                 breakP4=div*(barsnum_M1-4-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                 if(nowp<breakP1-50*d_point)
                 {
                    escape1_pos=iHighest(High_M1,barsnum_M1-point1_pos,barsnum_M1-1);
                    escape1_=DoubleToString(High_M1[escape1_pos],8);
                    ObjectSetString(0,"escapeS",OBJPROP_TEXT,"1");
                    ObjectCreate(0,"escapeSt",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                    ObjectSetString(0,"escape1",OBJPROP_TEXT,escape1_);
                    ObjectCreate(0,"escape1t",OBJ_ARROW_THUMB_UP,0,Time_M1[escape1_pos],High_M1[escape1_pos]);
                    time1_=TimeToString(Time_M5[barsnum_M5-1]);
                    ObjectSetString(0,"estime_po",OBJPROP_TEXT,time1_);
                    return;
                 }
                 if(Low_M1[barsnum_M1-3]<breakP3-5*d_point)
                 {
                    if((nowp<Low_M1[barsnum_M1-2]-5*d_point)&&(Low_M1[barsnum_M1-2]<Low_M1[barsnum_M1-3])&&(Low_M1[barsnum_M1-4]>=breakP4))
                    {
                       escape1_pos=iHighest(High_M1,barsnum_M1-point1_pos,barsnum_M1-1);
                       escape1_=DoubleToString(High_M1[escape1_pos],8);
                       ObjectSetString(0,"escapeS",OBJPROP_TEXT,"1");
                       ObjectCreate(0,"escapeSt",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                       ObjectSetString(0,"escape1",OBJPROP_TEXT,escape1_);
                       ObjectCreate(0,"escape1t",OBJ_ARROW_THUMB_UP,0,Time_M1[escape1_pos],High_M1[escape1_pos]);
                       time1_=TimeToString(Time_M5[barsnum_M5-1]);
                       ObjectSetString(0,"estime_po",OBJPROP_TEXT,time1_);
                       return;
                    }
                 }
              }
           }
           else
           {
               escape1=StringToDouble(ObjectGetString(0,"escape1",OBJPROP_TEXT,0));
               time1=StringToTime(ObjectGetString(0,"estime_po",OBJPROP_TEXT,0));
               if(nowp>escape1)
               {
                  ObjectDelete(0,"escapeS");
                  ObjectDelete(0,"escapeSt");
                  ObjectDelete(0,"escape1");
                  ObjectDelete(0,"escape1t");
                  ObjectDelete(0,"estime_po");
                  return;
               }
               for(i=0;i<tlines_D;i++)
               {
                   if((Time_M1[LineShow_D[i][1]]<time1)&&(High_M1[LineShow_D[i][1]]>escape1-(escape1-nowp)/3))
                   {
                      flag_escape1_3=1;
                      break;
                   }
               }
               if(flag_escape1_3==1)
               {
                  dis=LineShow_D[i][0]-LineShow_D[i][1];
                  if(dis!=0)
                  {
                     div=High_M1[LineShow_D[i][0]]-High_M1[LineShow_D[i][1]];
                     breakP1=div*(barsnum_M1-1-LineShow_D[i][0])/dis+High_M1[LineShow_D[i][0]];
                     kuan=div*(LineShow_D[i][2]-LineShow_D[i][0])/dis+High_M1[LineShow_D[i][0]]-Low_M1[LineShow_D[i][2]];
                     if(nowp>breakP1-kuan/10)
                     {
                        fsell(0,vol_full/2);
                        closeby_buy();
                        Alert("没赚15点出一半");
                        ObjectDelete(0,"escapeS");
                        ObjectDelete(0,"escapeSt");
                        ObjectDelete(0,"escape1");
                        ObjectDelete(0,"escape1t");
                        ObjectDelete(0,"estime_po");
                        return;
                     }
                  }
               }
           }
        }
        if((ObjectGetString(0,"escape_mode",OBJPROP_TEXT,0)=="1")&&(flag_vol==1))//赚15点，破3-4出一半
        {
            for(i=0;i<tlines_U;i++)
            {
                if((LineShow_U[i][1]<point3_pos)||(Low_M1[LineShow_U[i][1]]<point3+(nowp-point3)/3))
                break;
            }
            if(i<tlines_U)dis=LineShow_U[i][0]-LineShow_U[i][1];
            else dis=0;
            if(dis!=0)
            {
               div=Low_M1[LineShow_U[i][0]]-Low_M1[LineShow_U[i][1]];
               breakP1=div*(barsnum_M1-1-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
               breakP3=div*(barsnum_M1-3-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
               breakP4=div*(barsnum_M1-4-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
               if(nowp<breakP1-50*d_point)
               {
                  fsell(0,vol_full/2);
                  closeby_buy();
                  Alert("赚15点，破3-4出一半");
                  return;
               }
               if(Low_M1[barsnum_M1-3]<breakP3-5*d_point)
               {
                  if((nowp<Low_M1[barsnum_M1-2]-5*d_point)&&(Low_M1[barsnum_M1-2]<Low_M1[barsnum_M1-3])&&(Low_M1[barsnum_M1-4]>=breakP4))
                  {
                      fsell(0,vol_full/2);
                      closeby_buy();
                      Alert("赚15点，破3-4出一半");
                      return; 
                  }
               }
           }
        }
        if((flag_vol==1)&&(ObjectGetString(0,"escape_mode",OBJPROP_TEXT,0)=="2"))//25点以上
        {
           if(profit>vol_full*500)
           {
              SL=PositionGetDouble(POSITION_PRICE_OPEN);
              if(sl>SL)trade.PositionModify(_Symbol,SL,0);
           }
           if(ObjectGetString(0,"escapeS",OBJPROP_TEXT,0)!="2")//破通道出1和S
           {
              for(i=0;i<tlines_U-1;i++)
              {
                  dis=LineShow_U[i][0]-LineShow_U[i][1];
                  if(dis!=0)
                  {
                     div=Low_M1[LineShow_U[i][0]]-Low_M1[LineShow_U[i][1]];
                     breakP1=div*(barsnum_M1-1-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                     dis=LineShow_U[i+1][0]-LineShow_U[i+1][1];
                     if(dis!=0)
                     {
                        div=Low_M1[LineShow_U[i+1][0]]-Low_M1[LineShow_U[i+1][1]];
                        breakP11=div*(barsnum_M1-1-LineShow_U[i+1][0])/dis+Low_M1[LineShow_U[i+1][0]];
                        if(breakP1-breakP11>200*d_point)break;
                     }
                     else break;
                  }
              }
              if(i<tlines_U)dis=LineShow_U[i][0]-LineShow_U[i][1];
              else dis=0;
              if(dis!=0)
              {
                 div=Low_M1[LineShow_U[i][0]]-Low_M1[LineShow_U[i][1]];
                 breakP1=div*(barsnum_M1-1-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                 breakP3=div*(barsnum_M1-3-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                 breakP4=div*(barsnum_M1-4-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                 if(nowp<breakP1-50*d_point)
                 {
                    ObjectSetString(0,"escapeS",OBJPROP_TEXT,"2");
                    if(ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]]<ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]])
                    {
                       zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
                       time1=Time_M5[ZigZagBuffer_pos_M5[2]];
                    }
                    else
                    {
                        zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
                        time1=Time_M5[ZigZagBuffer_pos_M5[1]];
                    }
                    escape1_=DoubleToString(zig1,8);
                    ObjectCreate(0,"escapeSt",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                    ObjectSetString(0,"escape1",OBJPROP_TEXT,escape1_);
                    ObjectCreate(0,"escape1t",OBJ_ARROW_THUMB_UP,0,time1,zig1);
                    time1_=TimeToString(Time_M5[barsnum_M5-1]);
                    ObjectSetString(0,"estime_po",OBJPROP_TEXT,time1_);
                    return;
                 }
                 if(Low_M1[barsnum_M1-3]<breakP3-5*d_point)
                 {
                    if((nowp<Low_M1[barsnum_M1-2]-5*d_point)&&(Low_M1[barsnum_M1-2]<Low_M1[barsnum_M1-3])&&(Low_M1[barsnum_M1-4]>=breakP4))
                    {
                       ObjectSetString(0,"escapeS",OBJPROP_TEXT,"2");
                       if(ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]]<ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]])
                       {
                          zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
                          time1=Time_M5[ZigZagBuffer_pos_M5[2]];
                       }
                       else
                       {
                           zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
                           time1=Time_M5[ZigZagBuffer_pos_M5[1]];
                       }
                       escape1_=DoubleToString(zig1,8);
                       ObjectCreate(0,"escapeSt",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                       ObjectSetString(0,"escape1",OBJPROP_TEXT,escape1_);
                       ObjectCreate(0,"escape1t",OBJ_ARROW_THUMB_UP,0,time1,zig1);
                       time1_=TimeToString(Time_M5[barsnum_M5-1]);
                       ObjectSetString(0,"estime_po",OBJPROP_TEXT,time1_);
                       return;
                    }
                 }
              }
           }
           if(ObjectGetString(0,"escapeS",OBJPROP_TEXT,0)=="1")
           {
              ObjectDelete(0,"escapeS");
              ObjectDelete(0,"escapeSt");
              ObjectDelete(0,"estime_po");
              ObjectDelete(0,"escape1");
              ObjectDelete(0,"escape1t");
              ObjectDelete(0,"escape2");
              ObjectDelete(0,"escape2t");
              return;
           }
           if(ObjectGetString(0,"escapeS",OBJPROP_TEXT,0)=="2")
           {
              if(ObjectGetString(0,"escape2",OBJPROP_TEXT,0)=="0")
              {
                 escape1=StringToDouble(ObjectGetString(0,"escape1",OBJPROP_TEXT,0));
                 time1=StringToTime(ObjectGetString(0,"estime_po",OBJPROP_TEXT,0));
                 if(nowp>escape1)
                 {
                    ObjectSetString(0,"escape2",OBJPROP_TEXT,"A");//代表打破1点
                    return;
                 }
                 zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
                 zig2=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
                 time2=Time_M5[ZigZagBuffer_pos_M5[2]];
                 if((zig1>zig2)&&(time2>=time1))
                 {
                    escape2_=DoubleToString(zig2,8);
                    ObjectSetString(0,"escape2",OBJPROP_TEXT,escape2_);
                    ObjectCreate(0,"escape2t",OBJ_ARROW_THUMB_UP,0,time2,zig2);
                    return;
                 }
             }
             else
             {
                 if(ObjectGetString(0,"escape2",OBJPROP_TEXT,0)=="A")//破最小的通道出
                 {
                    if(ObjectGetString(0,"beforeS_2",OBJPROP_TEXT,0)=="0")
                    {
                       i=0;
                       if(i<tlines_U)dis=LineShow_U[i][0]-LineShow_U[i][1];
                       else dis=0;
                       if(dis!=0)
                       {
                          div=Low_M1[LineShow_U[i][0]]-Low_M1[LineShow_U[i][1]];
                          breakP1=div*(barsnum_M1-1-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                          breakP3=div*(barsnum_M1-3-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                          breakP4=div*(barsnum_M1-4-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                          if(nowp<breakP1-50*d_point)
                          {
                             timeS_2_=TimeToString(Time_M5[barsnum_M5-1]);
                             escape1_2=High_M1[iHighest(High_M1,barsnum_M1-LineShow_U[i][1],barsnum_M1-1)];
                             escape1_2_=DoubleToString(escape1_2,8);
                             ObjectSetString(0,"beforeS_2",OBJPROP_TEXT,timeS_2_);
                             ObjectSetString(0,"escape1_2",OBJPROP_TEXT,escape1_2_);
                             ObjectCreate(0,"escapeS_2t",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                             return;
                          }
                          if(Low_M1[barsnum_M1-3]<breakP3-5*d_point)
                          {
                             if((nowp<Low_M1[barsnum_M1-2]-5*d_point)&&(Low_M1[barsnum_M1-2]<Low_M1[barsnum_M1-3])&&(Low_M1[barsnum_M1-4]>=breakP4))
                             {
                                timeS_2_=TimeToString(Time_M5[barsnum_M5-1]);
                                escape1_2=High_M1[iHighest(High_M1,barsnum_M1-LineShow_U[i][1],barsnum_M1-1)];
                                escape1_2_=DoubleToString(escape1_2,8);
                                ObjectSetString(0,"beforeS_2",OBJPROP_TEXT,timeS_2_);
                                ObjectSetString(0,"escape1_2",OBJPROP_TEXT,escape1_2_);
                                ObjectCreate(0,"escapeS_2t",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                                return;
                             }
                          }
                       }
                    }
                    else
                    {
                        escape1_2=StringToDouble(ObjectGetString(0,"escape1_2",OBJPROP_TEXT,0));
                        if(nowp>escape1_2)
                        {
                           ObjectDelete(0,"beforeS_2");
                           ObjectDelete(0,"escape1_2");
                           ObjectDelete(0,"escapeS_2t");
                           ObjectDelete(0,"escape2_2");
                           ObjectDelete(0,"escape2_2t");
                           return;
                        }
                        if(ObjectGetString(0,"escape2_2",OBJPROP_TEXT,0)=="0")
                        {
                           escape2_2_=DoubleToString(nowp,8);
                           ObjectSetString(0,"escape2_2",OBJPROP_TEXT,escape2_2_);
                           ObjectCreate(0,"escape2_2t",OBJ_ARROW_THUMB_UP,0,Time_M5[barsnum_M5-1],nowp);
                           return;
                        }
                        else
                        {
                           escape2_2=StringToDouble(ObjectGetString(0,"escape2_2",OBJPROP_TEXT,0));
                           timeS_2=StringToTime(ObjectGetString(0,"beforeS_2",OBJPROP_TEXT,0));
                           if(Time_M5[barsnum_M5-2]>timeS_2)
                           {
                              if(Low_M5[barsnum_M5-2]<escape2_2)
                              {
                                 escape2_2_=DoubleToString(Low_M5[barsnum_M5-2],8);
                                 ObjectSetString(0,"escape2_2",OBJPROP_TEXT,escape2_2_);
                                 ObjectSetDouble(0,"escape2_2t",OBJPROP_PRICE,Low_M5[barsnum_M5-2]);
                                 ObjectSetInteger(0,"escape2_2t",OBJPROP_TIME,Time_M5[barsnum_M5-2]);
                                 return;
                              }
                              if((Low_M5[barsnum_M5-2]>=escape2_2)&&(nowp<escape2_2))
                              {
                                 fsell(0,vol_full/2);
                                 closeby_buy();
                                 ObjectDelete(0,"escape_mode");
                                 ObjectDelete(0,"escapeS");
                                 ObjectDelete(0,"escapeSt");
                                 ObjectDelete(0,"estime_po");
                                 ObjectDelete(0,"escape1");
                                 ObjectDelete(0,"escape1t");
                                 ObjectDelete(0,"escape2");
                                 ObjectDelete(0,"escape2t");
                                 ObjectDelete(0,"beforeS_2");
                                 ObjectDelete(0,"escape1_2");
                                 ObjectDelete(0,"escapeS_2t");
                                 ObjectDelete(0,"escape2_2");
                                 ObjectDelete(0,"escape2_2t");
                                 Alert("25点以上左侧+123出场");
                                 return;
                              }
                           }
                        }
                    }
                 }
                 else//等下来以后破最小的通道出
                 {
                     escape1=StringToDouble(ObjectGetString(0,"escape1",OBJPROP_TEXT,0));
                     time1=StringToTime(ObjectGetString(0,"estime_po",OBJPROP_TEXT,0));
                     if(nowp>escape1)
                     {
                        ObjectSetString(0,"escape2",OBJPROP_TEXT,"A");//代表打破1点
                        return;
                     }
                     escape2=StringToDouble(ObjectGetString(0,"escape2",OBJPROP_TEXT,0));
                     zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
                     zig2=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
                     time2=Time_M5[ZigZagBuffer_pos_M5[2]];
                     escape2_time=ObjectGetInteger(0,"escape2t",OBJPROP_TIME,0);
                     if((zig1<zig2)&&(time2>=escape2_time))
                     {
                        close_buy();
                        Alert("25点以上，123全出");
                        ObjectsDeleteAll(0,0,OBJ_ARROW_THUMB_UP);
                        ObjectsDeleteAll(0,0,OBJ_LABEL);
                        return;
                     }
                  }
              }
           }
        }
     }
     if((ObjectGetString(0,"escape_ag",OBJPROP_TEXT,0)!="0")&&(flag_vol==1))//接过单,破接单之前的通道123出一半，(或者破外面的通道直接全出)
     {
         price_ag=StringToDouble(ObjectGetString(0,"price_ag",OBJPROP_TEXT,0));
         time_ag=StringToTime(ObjectGetString(0,"escape_ag",OBJPROP_TEXT,0));
         if(ObjectGetString(0,"escape_mode",OBJPROP_TEXT,0)!="2")
         {
            if(nowp-price_ag>=250*d_point)ObjectSetString(0,"escape_mode",OBJPROP_TEXT,"2");
            else ObjectSetString(0,"escape_mode",OBJPROP_TEXT,"1");
         }
         if(ObjectGetString(0,"escape_mode",OBJPROP_TEXT,0)=="0")
         {
            i=0;
            if(i<tlines_U)dis=LineShow_U[i][0]-LineShow_U[i][1];
            else dis=0;
            if(dis!=0)
            {
               div=Low_M1[LineShow_U[i][0]]-Low_M1[LineShow_U[i][1]];
               breakP1=div*(barsnum_M1-1-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
               breakP3=div*(barsnum_M1-3-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
               breakP4=div*(barsnum_M1-4-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
               if(nowp<breakP1-70*d_point)
               {
                  fsell(0,vol_full/2);
                  closeby_buy();
                  Alert("接单后亏损，破最小通路出一半");
                  return;
               }
               if(Low_M1[barsnum_M1-3]<breakP3-5*d_point)
               {
                  if((nowp<Low_M1[barsnum_M1-2]-5*d_point)&&(Low_M1[barsnum_M1-2]<Low_M1[barsnum_M1-3])&&(Low_M1[barsnum_M1-4]>=breakP4))
                  {
                     fsell(0,vol_full/2);
                     closeby_buy();
                     Alert("接单后亏损，破最小通路出一半");
                     return; 
                  }
               }
            }
         }
         if(ObjectGetString(0,"escape_mode",OBJPROP_TEXT,0)=="1")
         {
            for(i=0;i<tlines_U;i++)
            {
                if((LineShow_U[i][1]<point3_pos)||(Low_M1[LineShow_U[i][1]]<point3+(nowp-point3)/3))
                break;
            }
            if(i<tlines_U)dis=LineShow_U[i][0]-LineShow_U[i][1];
            else dis=0;
            if(dis!=0)
            {
               div=Low_M1[LineShow_U[i][0]]-Low_M1[LineShow_U[i][1]];
               breakP1=div*(barsnum_M1-1-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
               breakP3=div*(barsnum_M1-3-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
               breakP4=div*(barsnum_M1-4-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
               if(nowp<breakP1-50*d_point)
               {
                  fsell(0,vol_full/2);
                  closeby_buy();
                  Alert("接单后，破3-4出一半");
                  return;
               }
               if(Low_M1[barsnum_M1-3]<breakP3-5*d_point)
               {
                  if((nowp<Low_M1[barsnum_M1-2]-5*d_point)&&(Low_M1[barsnum_M1-2]<Low_M1[barsnum_M1-3])&&(Low_M1[barsnum_M1-4]>=breakP4))
                  {
                     fsell(0,vol_full/2);
                     closeby_buy();
                     Alert("接单后，破3-4出一半");
                     return; 
                  }
               }
            }
         }
         if(ObjectGetString(0,"escape_mode",OBJPROP_TEXT,0)=="2")
         {
            if(ObjectGetString(0,"escape",OBJPROP_TEXT,0)=="0")
            {
               time_ag=StringToTime(ObjectGetString(0,"escape_ag",OBJPROP_TEXT,0));
               for(i=0;i<tlines_U;i++)
               {
                   if(Time_M1[LineShow_U[i][1]]<time_ag)break;
               }
               if((middle_TL>0)&&(middle_TL-1<i))i=middle_TL-1;
               if(i<tlines_U)dis=LineShow_U[i][0]-LineShow_U[i][1];
               else dis=0;
               if(dis!=0)
               {
                  div=Low_M1[LineShow_U[i][0]]-Low_M1[LineShow_U[i][1]];
                  breakP1=div*(barsnum_M1-1-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                  breakP3=div*(barsnum_M1-3-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                  breakP4=div*(barsnum_M1-4-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                  if(nowp<breakP1-50*d_point)
                  {
                     ObjectSetString(0,"escape",OBJPROP_TEXT,"1");
                     if(i==middle_TL-1)
                        ObjectSetString(0,"escape",OBJPROP_TEXT,"2");
                     escapeS_=DoubleToString(breakP1,8);
                     ObjectSetString(0,"escapeS",OBJPROP_TEXT,escapeS_);
                     if(ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]]<ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]])
                     {
                        zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
                        time1=Time_M5[ZigZagBuffer_pos_M5[2]];
                     }
                     else
                     {
                         zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
                         time1=Time_M5[ZigZagBuffer_pos_M5[1]];
                     }
                     escape1_=DoubleToString(zig1,8);
                     ObjectCreate(0,"escapeSt",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                     ObjectSetString(0,"escape1",OBJPROP_TEXT,escape1_);
                     ObjectCreate(0,"escape1t",OBJ_ARROW_THUMB_UP,0,time1,zig1);
                     time1_=TimeToString(Time_M5[barsnum_M5-1]);
                     ObjectSetString(0,"estime_po",OBJPROP_TEXT,time1_);
                     return;
                  }
                  if(Low_M1[barsnum_M1-3]<breakP3-5*d_point)
                  {
                     if((nowp<Low_M1[barsnum_M1-2]-5*d_point)&&(Low_M1[barsnum_M1-2]<Low_M1[barsnum_M1-3])&&(Low_M1[barsnum_M1-4]>=breakP4))
                     {
                        ObjectSetString(0,"escape",OBJPROP_TEXT,"1");
                        if(i==middle_TL-1)
                           ObjectSetString(0,"escape",OBJPROP_TEXT,"2");
                        escapeS_=DoubleToString(breakP1,8);
                        ObjectSetString(0,"escapeS",OBJPROP_TEXT,escapeS_);
                        if(ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]]<ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]])
                        {
                           zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
                           time1=Time_M5[ZigZagBuffer_pos_M5[2]];
                        }
                        else
                        {
                            zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
                            time1=Time_M5[ZigZagBuffer_pos_M5[1]];
                        }
                        escape1_=DoubleToString(zig1,8);
                        ObjectCreate(0,"escapeSt",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                        ObjectSetString(0,"escape1",OBJPROP_TEXT,escape1_);
                        ObjectCreate(0,"escape1t",OBJ_ARROW_THUMB_UP,0,time1,zig1);
                        time1_=TimeToString(Time_M5[barsnum_M5-1]);
                        ObjectSetString(0,"estime_po",OBJPROP_TEXT,time1_);
                        return;
                    }
                  }
               }
            }
            else
            {
                escapeS=StringToDouble(ObjectGetString(0,"escapeS",OBJPROP_TEXT,0));
                escape1=StringToDouble(ObjectGetString(0,"escape1",OBJPROP_TEXT,0));
                estime=StringToTime(ObjectGetString(0,"estime_po",OBJPROP_TEXT,0));
                if(nowp>escape1)
                {
                   ObjectDelete(0,"escape");
                   ObjectDelete(0,"escapeS");
                   ObjectDelete(0,"escapeSt");
                   ObjectDelete(0,"estime_po");
                   ObjectDelete(0,"escape1");
                   ObjectDelete(0,"escape1t");
                   ObjectDelete(0,"escape2");
                   ObjectDelete(0,"escape2t");
                   ObjectDelete(0,"escapeS_2to3");
                   ObjectDelete(0,"escape1_2to3");
                   ObjectDelete(0,"escapeS_2to3t");
                   ObjectDelete(0,"escape2_2to3");
                   ObjectDelete(0,"escape2_2to3t");
                   return;
                }
                if(ObjectGetString(0,"escape2",OBJPROP_TEXT,0)=="0")
                {
                   zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
                   zig2=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
                   time2=Time_M5[ZigZagBuffer_pos_M5[2]];
                   if((zig1>zig2)&&(time2>=estime))
                   {
                     point2_=DoubleToString(zig2,8);
                     ObjectSetString(0,"escape2",OBJPROP_TEXT,point2_);
                     ObjectCreate(0,"escape2t",OBJ_ARROW_THUMB_UP,0,time2,zig2);
                     return;
                   }
                }
                else
                {
                    if(ObjectGetString(0,"escape",OBJPROP_TEXT,0)=="1")vol_now=vol_full/2;
                    if(ObjectGetString(0,"escape",OBJPROP_TEXT,0)=="2")vol_now=vol_full;
                    escape2=StringToDouble(ObjectGetString(0,"escape2",OBJPROP_TEXT,0));
                    zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
                    zig2=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
                    time3=Time_M5[ZigZagBuffer_pos_M5[2]+2];
                    int flag_2to3=0;
                    for(i=0;i<tlines_U;i++)
                    {
                        if((Time_M1[LineShow_U[i][1]]>estime)&&(Low_M1[LineShow_U[i][1]]<escape2+(nowp-escape2)/3))
                        {
                           flag_2to3=1; 
                           break;
                        }
                    }
                    if(ObjectGetString(0,"escapeS_2to3",OBJPROP_TEXT,0)=="0")
                    {
                       if((flag_2to3==1)&&(i<tlines_U))
                       {
                          dis=LineShow_U[i][0]-LineShow_U[i][1];
                          if(dis!=0)
                          {
                             div=Low_M1[LineShow_U[i][0]]-Low_M1[LineShow_U[i][1]];
                             breakP1=div*(barsnum_M1-1-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                             breakP3=div*(barsnum_M1-3-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                             breakP4=div*(barsnum_M1-4-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                          }
                          if(nowp<breakP1-50*d_point)
                          {
                             timeS_2to3_=TimeToString(Time_M5[barsnum_M5-1]);
                             escape1_2to3=High_M1[iHighest(High_M1,barsnum_M1-LineShow_U[i][1],barsnum_M1-1)];
                             escape1_2to3_=DoubleToString(escape1_2to3,8);
                             ObjectSetString(0,"escapeS_2to3",OBJPROP_TEXT,timeS_2to3_);
                             ObjectSetString(0,"escape1_2to3",OBJPROP_TEXT,escape1_2to3_);
                             ObjectCreate(0,"escapeS_2to3t",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                             return;
                          }
                          if(Low_M1[barsnum_M1-3]<breakP3-5*d_point)
                          {
                             if((nowp<Low_M1[barsnum_M1-2]-5*d_point)&&(Low_M1[barsnum_M1-2]<Low_M1[barsnum_M1-3])&&(Low_M1[barsnum_M1-4]>=breakP4))
                             {
                                  timeS_2to3_=TimeToString(Time_M5[barsnum_M5-1]);
                                  escape1_2to3=High_M1[iHighest(High_M1,barsnum_M1-LineShow_U[i][1],barsnum_M1-1)];
                                  escape1_2to3_=DoubleToString(escape1_2to3,8);
                                  ObjectSetString(0,"escapeS_2to3",OBJPROP_TEXT,timeS_2to3_);
                                  ObjectSetString(0,"escape1_2to3",OBJPROP_TEXT,escape1_2to3_);
                                  ObjectCreate(0,"escapeS_2to3t",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                                  return;
                              }
                          }
                       }
                    }
                    else
                    {
                        escape1_2to3=StringToDouble(ObjectGetString(0,"escape1_2to3",OBJPROP_TEXT,0));
                        if(nowp>escape1_2to3)
                        {
                           ObjectDelete(0,"escapeS_2to3");
                           ObjectDelete(0,"escape1_2to3");
                           ObjectDelete(0,"escapeS_2to3t");
                           ObjectDelete(0,"escape2_2to3");
                           ObjectDelete(0,"escape2_2to3t");
                           return;
                        }
                        if(ObjectGetString(0,"escape2_2to3",OBJPROP_TEXT,0)=="0")
                        {
                           escape2_2to3_=DoubleToString(nowp,8);
                           ObjectSetString(0,"escape2_2to3",OBJPROP_TEXT,escape2_2to3_);
                           ObjectCreate(0,"escape2_2to3t",OBJ_ARROW_THUMB_UP,0,Time_M5[barsnum_M5-1],nowp);
                           return;
                        }
                       else
                       {
                            escape2_2to3=StringToDouble(ObjectGetString(0,"escape2_2to3",OBJPROP_TEXT,0));
                            timeS_2to3=StringToTime(ObjectGetString(0,"escapeS_2to3",OBJPROP_TEXT,0));
                            if(Time_M5[barsnum_M5-2]>timeS_2to3)
                            {
                               if(Low_M5[barsnum_M5-2]<escape2_2to3)
                               {
                                  escape2_2to3_=DoubleToString(Low_M5[barsnum_M5-2],8);
                                  ObjectSetString(0,"escape2_2to3",OBJPROP_TEXT,escape2_2to3_);
                                  ObjectSetDouble(0,"escape2_2to3t",OBJPROP_PRICE,Low_M5[barsnum_M5-2]);
                                  ObjectSetInteger(0,"escape2_2to3t",OBJPROP_TIME,Time_M5[barsnum_M5-2]);
                                  return;
                               }
                               if((Low_M5[barsnum_M5-2]>=escape2_2to3)&&(nowp<escape2_2to3))
                               {
                                  close_buy();
                                  Alert("接单以后破中通道2次123全出");
                                  ObjectDelete(0,"escape");
                                  ObjectDelete(0,"escapeS");
                                  ObjectDelete(0,"escapeSt");
                                  ObjectDelete(0,"estime_po");
                                  ObjectDelete(0,"escape1");
                                  ObjectDelete(0,"escape1t");
                                  ObjectDelete(0,"escape2");
                                  ObjectDelete(0,"escape2t");
                                  ObjectDelete(0,"escapeS_2to3");
                                  ObjectDelete(0,"escapeS_2to3t");
                                  ObjectDelete(0,"escape2_2to3");
                                  ObjectDelete(0,"escape2_2to3t");
                                  return;
                               }
                            }
                        }
                    }
                    if((zig1<zig2)&&(time3>=estime)&&(nowp<escapeS))
                    {
                       close_buy();
                       Alert("接单以后破通道123全出，Z字线123");
                       ObjectDelete(0,"escape");
                       ObjectDelete(0,"escapeS");
                       ObjectDelete(0,"escapeSt");
                       ObjectDelete(0,"estime_po");
                       ObjectDelete(0,"escape1");
                       ObjectDelete(0,"escape1t");
                       ObjectDelete(0,"escape2");
                       ObjectDelete(0,"escape2t");
                       ObjectDelete(0,"escapeS_2to3");
                       ObjectDelete(0,"escapeS_2to3t");
                       ObjectDelete(0,"escape2_2to3");
                       ObjectDelete(0,"escape2_2to3t");
                       return;
                    }
                }
            }
        }
     }
     if(flag_vol==2)
     {
        i=barsnum_M1-1;
        while((Time_M1[i]>deal_time)&&(Time_M1[i]>Time_D1[barsnum_D1-10]))
        {
              i--;
        }
        int pointh_pos=iHighest(High_M1,barsnum_M1-i,barsnum_M1-5);
        double pointh=High_M1[pointh_pos];
        double pointl;
        if(ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]]<ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]])
           pointl=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
        else pointl=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
        if(nowp>pointh)
        {
           time_ag_=TimeToString(Time_M5[barsnum_M5-1]);
           ObjectSetString(0,"escape_ag",OBJPROP_TEXT,time_ag_);
           price_ag_=DoubleToString(pointl,8);
           ObjectSetString(0,"price_ag",OBJPROP_TEXT,price_ag_);
           fbuy(sl,vol_full/2);
           Alert("接一半");
           ObjectDelete(0,"escape_mode");
           ObjectDelete(0,"escapeS");
           ObjectDelete(0,"escapeSt");
           ObjectDelete(0,"estime_po");
           ObjectDelete(0,"escape1");
           ObjectDelete(0,"escape1t");
           ObjectDelete(0,"escape2");
           ObjectDelete(0,"escape2t");
           return;
        }
        if(ObjectGetString(0,"escape1_2to3",OBJPROP_TEXT,0)!="0")
        {
           escape1_2to3=StringToDouble(ObjectGetString(0,"escape1_2to3",OBJPROP_TEXT,0));
           if(nowp>escape1_2to3)
           {
              time_ag_=TimeToString(Time_M5[barsnum_M5-1]);
              ObjectSetString(0,"escape_ag",OBJPROP_TEXT,time_ag_);
              price_ag_=DoubleToString(pointl,8);
              ObjectSetString(0,"price_ag",OBJPROP_TEXT,price_ag_);
              fbuy(sl,vol_full/2);
              Alert("双123的接单");
              ObjectDelete(0,"escape_mode");
              ObjectDelete(0,"escapeS");
              ObjectDelete(0,"escapeSt");
              ObjectDelete(0,"estime_po");
              ObjectDelete(0,"escape1");
              ObjectDelete(0,"escape1t");
              ObjectDelete(0,"escape2");
              ObjectDelete(0,"escape2t");
              ObjectDelete(0,"escape1_2to3");
              return;
           }
        }
        if(ObjectGetString(0,"escapeS",OBJPROP_TEXT,0)=="0")
        {
           for(i=0;i<tlines_U-1;i++)
           {
               dis=LineShow_U[i][0]-LineShow_U[i][1];
               if(dis!=0)
               {
                  div=Low_M1[LineShow_U[i][0]]-Low_M1[LineShow_U[i][1]];
                  breakP1=div*(barsnum_M1-1-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                  dis=LineShow_U[i+1][0]-LineShow_U[i+1][1];
                  if(dis!=0)
                  {
                     div=Low_M1[LineShow_U[i+1][0]]-Low_M1[LineShow_U[i+1][1]];
                     breakP11=div*(barsnum_M1-1-LineShow_U[i+1][0])/dis+Low_M1[LineShow_U[i+1][0]];
                     if(breakP1-breakP11>200*d_point)break;
                  }
                  else break;
               }
           }
           if(big_TL>0)
           {
              datetime nowtime=SymbolInfoInteger(_Symbol,SYMBOL_TIME);//当前时间
              HistorySelect(Time_H4[barsnum_H4-60],nowtime);
              int order_num=HistoryOrdersTotal();//选择的历史区间内总交易次数
              int ticket=HistoryOrderGetTicket(order_num-1);//这是选择订单的ticket
              datetime last_deal_time=HistoryOrderGetInteger(ticket,ORDER_TIME_DONE);
              if(HistoryOrderGetInteger(ticket,ORDER_TYPE)==ORDER_TYPE_SELL)
              {
                 for(i=0;i<tlines_U;i++)
                 {
                     if(Time_M1[LineShow_U[i][1]]<last_deal_time)break;
                 }
              }
           }
           if(i<tlines_U)dis=LineShow_U[i][0]-LineShow_U[i][1];
           else dis=0;
           if(dis!=0)
           {
              div=Low_M1[LineShow_U[i][0]]-Low_M1[LineShow_U[i][1]];
              breakP1=div*(barsnum_M1-1-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
              breakP3=div*(barsnum_M1-3-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
              breakP4=div*(barsnum_M1-4-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
              if(nowp<breakP1-50*d_point)
              {
                 escapeS_=DoubleToString(breakP1,8);
                 ObjectSetString(0,"escapeS",OBJPROP_TEXT,escapeS_);
                 ObjectCreate(0,"escapeSt",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                 findperiod2();
                 return;
              }
              if(Low_M1[barsnum_M1-3]<breakP3-5*d_point)
              {
                 if((nowp<Low_M1[barsnum_M1-2]-5*d_point)&&(Low_M1[barsnum_M1-2]<Low_M1[barsnum_M1-3])&&(Low_M1[barsnum_M1-4]>=breakP4))
                 {
                    escapeS_=DoubleToString(breakP1,8);
                    ObjectSetString(0,"escapeS",OBJPROP_TEXT,escapeS_);
                    ObjectCreate(0,"escapeSt",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                    findperiod2();
                    return;
                 }
              }
           }
        }
        else
        {
            escapeS=StringToDouble(ObjectGetString(0,"escapeS",OBJPROP_TEXT,0));
            escape1=StringToDouble(ObjectGetString(0,"escape1",OBJPROP_TEXT,0));
            estime=StringToTime(ObjectGetString(0,"estime_po",OBJPROP_TEXT,0));
            period=StringToInteger(ObjectGetString(0,"trade_period",OBJPROP_TEXT,0));
            if((nowp<escapeS-(escape1-escapeS)/3*2)&&(escape1-escapeS>200*d_point)&&(big_TL<0))
            {
               close_buy();
               Alert("2/3出剩下一半");
               ObjectsDeleteAll(0,0,OBJ_ARROW_THUMB_UP);
               ObjectsDeleteAll(0,0,OBJ_LABEL);
               return;
            }
            if(ObjectGetString(0,"escape2",OBJPROP_TEXT,0)=="0")
            {
               if(nowp>escape1)
               {
                  ObjectDelete(0,"escape1");
                  ObjectDelete(0,"escape1t");
                  ObjectDelete(0,"escapeS");
                  ObjectDelete(0,"escapeSt");
                  return;
               }
               if(period==2)
               {
                  zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
                  zig2=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
                  time2=Time_M5[ZigZagBuffer_pos_M5[2]];
               }
               if(period==3)
               {
                  zig1=ZigZagBuffer_M15[ZigZagBuffer_pos_M15[1]];
                  zig2=ZigZagBuffer_M15[ZigZagBuffer_pos_M15[2]];
                  time2=Time_M15[ZigZagBuffer_pos_M15[2]];
               }
               if((zig1>zig2)&&(time2>=estime))
               {
                  point2_=DoubleToString(zig2,8);
                  ObjectSetString(0,"escape2",OBJPROP_TEXT,point2_);
                  ObjectCreate(0,"escape2t",OBJ_ARROW_THUMB_UP,0,time2,zig2);
                  return;
               }
            }
            else
            {
                if(nowp>escape1)
                {
                   ObjectDelete(0,"escape1");
                   ObjectDelete(0,"escape1t");
                   ObjectDelete(0,"escapeS");
                   ObjectDelete(0,"escapeSt");
                   ObjectDelete(0,"escape2");
                   ObjectDelete(0,"escape2t");
                   return;
                }
                escape2=StringToDouble(ObjectGetString(0,"escape2",OBJPROP_TEXT,0));
                zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
                zig2=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
                time3=Time_M5[ZigZagBuffer_pos_M5[2]+2];
                int flag_2to3=0;
                for(i=0;i<tlines_U;i++)
                {
                    if((Time_M1[LineShow_U[i][1]]>estime)&&(Low_M1[LineShow_U[i][1]]<escape2+(nowp-escape2)/3))
                    {
                       flag_2to3=1; 
                       break;
                    }
                }
                if((flag_2to3==1)&&(i<tlines_D))
                {
                   dis=LineShow_U[i][0]-LineShow_U[i][1];
                   if(dis!=0)
                   {
                      div=Low_M1[LineShow_U[i][0]]-Low_M1[LineShow_U[i][1]];
                      breakP1=div*(barsnum_M1-1-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                      breakP3=div*(barsnum_M1-3-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                      breakP4=div*(barsnum_M1-4-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                      if(nowp<breakP1-50*d_point)
                      {
                         close_buy();
                         Alert("123出剩下一半");
                         ObjectsDeleteAll(0,0,OBJ_ARROW_THUMB_UP);
                         ObjectsDeleteAll(0,0,OBJ_LABEL);
                         return;
                      }
                      if(Low_M1[barsnum_M1-3]<breakP3-5*d_point)
                      {
                         if((nowp<Low_M1[barsnum_M1-2]-5*d_point)&&(Low_M1[barsnum_M1-2]<Low_M1[barsnum_M1-3])&&(Low_M1[barsnum_M1-4]>=breakP4))
                         {
                              close_buy();
                              Alert("123出剩下一半");
                              ObjectsDeleteAll(0,0,OBJ_ARROW_THUMB_UP);
                              ObjectsDeleteAll(0,0,OBJ_LABEL);
                              return;
                          }
                      }
                   }
                }
                if((zig1<zig2)&&(time3>=estime)&&(nowp<escapeS))
                {
                   close_buy();
                   Alert("123出剩下一半");
                   ObjectsDeleteAll(0,0,OBJ_ARROW_THUMB_UP);
                   ObjectsDeleteAll(0,0,OBJ_LABEL);
                   return;
                }
            }
        }
     }
}

void escapeB3()
{
     double vol_full=0.36;
     if(yuanyou==true)vol_full=3.6;
     double point1,point2,point3;
     string point1_,point2_,point3_;
     datetime point1_po;
     string point1_po_;
     int point1_pos=0,point3_pos=0;
     string point1_pos_,point3_pos_;
     point1=StringToDouble(ObjectGetString(0,"point1",OBJPROP_TEXT,0));
     point2=StringToDouble(ObjectGetString(0,"point2",OBJPROP_TEXT,0));
     point3=StringToDouble(ObjectGetString(0,"point3",OBJPROP_TEXT,0));
     datetime point1_time=ObjectGetInteger(0,"point1t",OBJPROP_TIME,0);
     datetime deal_time=StringToTime(ObjectGetString(0,"deal_time",OBJPROP_TEXT,0));
     double nowp=SymbolInfoDouble(_Symbol,SYMBOL_BID);
     double vol=PositionGetDouble(POSITION_VOLUME);
     double profit=PositionGetDouble(POSITION_PROFIT);
     double sl=PositionGetDouble(POSITION_SL);
     double deal_price=PositionGetDouble(POSITION_PRICE_OPEN);
     string deal_price_;
     double kuan;
     double SL;
     double escapeS;
     string escapeS_;
     int i,dis;
     double div,breakP1,breakP3,breakP4,breakP11;
     double escape1,escape2;
     string escape1_,escape2_;
     datetime point2_time,escape2_time;
     datetime estime;
     int period;
     double zig1,zig2;
     datetime time1,time2,time3,time_po;
     string time1_,time2_;
     int escape1_pos;
     int flag_escape1_3=0;
     datetime timeS_2;
     double escape1_2,escape2_2;
     string escape1_2_,escape2_2_,timeS_2_;
     datetime time_ag;
     string time_ag_;
     datetime timeS_2to3;
     double escape1_2to3,escape2_2to3;
     string timeS_2to3_,escape1_2to3_,escape2_2to3_;
     double price_ag;
     string price_ag_;
     int position_num=PositionsTotal();
     ulong position_ticket;
     int position_i=position_num;
     int position_sell_num=0;
     while(position_i>0)
     {
        position_ticket=PositionGetTicket(position_i-1);//这是仓位的ticket
        positioninfo.SelectByTicket(position_ticket);
        if((positioninfo.Symbol()==_Symbol)&&(positioninfo.PositionType()==POSITION_TYPE_BUY))
        {
            position_sell_num++;
        }
        position_i--;
     }
     int flag_vol=0;
     if((position_sell_num>1)||(vol==vol_full))
     {
         flag_vol=1;
     }
     if((position_sell_num==1)&&(vol==vol_full/2))
     {
         flag_vol=2;
     }
     if((flag_vol==1)&&(ObjectGetString(0,"escape_ag",OBJPROP_TEXT,0)=="0"))//赚了15个点
     {
        if(ObjectGetString(0,"deal_price",OBJPROP_TEXT,0)=="0")
        {
           deal_price_=DoubleToString(deal_price,8);
           ObjectSetString(0,"deal_price",OBJPROP_TEXT,deal_price_);
        }
        if(ObjectGetString(0,"escape_mode",OBJPROP_TEXT,0)=="0")
        {
           if(profit>=vol_full*150)
           {
              ObjectSetString(0,"escape_mode",OBJPROP_TEXT,"1");
           }
        }
        if(ObjectGetString(0,"escape_mode",OBJPROP_TEXT,0)=="1")
        {
           if(profit>=vol_full*250)
           {
              ObjectSetString(0,"escape_mode",OBJPROP_TEXT,"2");
           }
        }
     }
     /*if(ObjectGetString(0,"escape_ag",OBJPROP_TEXT,0)!="0")
     {
        deal_price=StringToDouble(ObjectGetString(0,"deal_price",OBJPROP_TEXT,0));
        if((nowp<deal_price-0.30)&&(deal_price!=0))
        {
           ObjectSetString(0,"escape_mode",OBJPROP_TEXT,"2");
        }
     }*/
     if(ObjectGetString(0,"point3",OBJPROP_TEXT,0)!="0")//如果有2点、3点
     {
        for(i=barsnum_M1-1;i>barsnum_M1-50000;i--)
        {
            if((Low_M1[i]<=point3)&&(point3_pos==0))point3_pos=i;
            if((Low_M1[i]<=point1)&&(point1_pos==0))
            {
               point1_pos=i;
               break;
            }
        }
     }
     if(ObjectGetString(0,"escape_ag",OBJPROP_TEXT,0)=="0")//没接过单
     {
        if((ObjectGetString(0,"escape_mode",OBJPROP_TEXT,0)=="0")&&(flag_vol==1))//没赚15点,破1-3或更早的通路出1-S，之后下来在下沿出一半
        {
           if(ObjectGetString(0,"escapeS",OBJPROP_TEXT,0)=="0")
           {
              for(i=0;i<tlines_U;i++)
              {
                  if((LineShow_U[i][1]<point3_pos)&&(Low_M1[LineShow_U[i][1]]<point3))
                  break;
              }
              if(i<tlines_U)dis=LineShow_U[i][0]-LineShow_U[i][1];
              else dis=0;
              if(dis!=0)
              {
                 div=Low_M1[LineShow_U[i][0]]-Low_M1[LineShow_U[i][1]];
                 breakP1=div*(barsnum_M1-1-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                 breakP3=div*(barsnum_M1-3-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                 breakP4=div*(barsnum_M1-4-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                 if(nowp<breakP1-50*d_point)
                 {
                    escape1_pos=iHighest(High_M1,barsnum_M1-point1_pos,barsnum_M1-1);
                    escape1_=DoubleToString(High_M1[escape1_pos],8);
                    ObjectSetString(0,"escapeS",OBJPROP_TEXT,"1");
                    ObjectCreate(0,"escapeSt",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                    ObjectSetString(0,"escape1",OBJPROP_TEXT,escape1_);
                    ObjectCreate(0,"escape1t",OBJ_ARROW_THUMB_UP,0,Time_M1[escape1_pos],High_M1[escape1_pos]);
                    time1_=TimeToString(Time_M5[barsnum_M5-1]);
                    ObjectSetString(0,"estime_po",OBJPROP_TEXT,time1_);
                    return;
                 }
                 if(Low_M1[barsnum_M1-3]<breakP3-5*d_point)
                 {
                    if((nowp<Low_M1[barsnum_M1-2]-5*d_point)&&(Low_M1[barsnum_M1-2]<Low_M1[barsnum_M1-3])&&(Low_M1[barsnum_M1-4]>=breakP4))
                    {
                       escape1_pos=iHighest(High_M1,barsnum_M1-point1_pos,barsnum_M1-1);
                       escape1_=DoubleToString(High_M1[escape1_pos],8);
                       ObjectSetString(0,"escapeS",OBJPROP_TEXT,"1");
                       ObjectCreate(0,"escapeSt",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                       ObjectSetString(0,"escape1",OBJPROP_TEXT,escape1_);
                       ObjectCreate(0,"escape1t",OBJ_ARROW_THUMB_UP,0,Time_M1[escape1_pos],High_M1[escape1_pos]);
                       time1_=TimeToString(Time_M5[barsnum_M5-1]);
                       ObjectSetString(0,"estime_po",OBJPROP_TEXT,time1_);
                       return;
                    }
                 }
              }
           }
           else
           {
               escape1=StringToDouble(ObjectGetString(0,"escape1",OBJPROP_TEXT,0));
               time1=StringToTime(ObjectGetString(0,"estime_po",OBJPROP_TEXT,0));
               if(nowp>escape1)
               {
                  ObjectDelete(0,"escapeS");
                  ObjectDelete(0,"escapeSt");
                  ObjectDelete(0,"escape1");
                  ObjectDelete(0,"escape1t");
                  ObjectDelete(0,"estime_po");
                  return;
               }
               for(i=0;i<tlines_D;i++)
               {
                   if((Time_M1[LineShow_D[i][1]]<time1)&&(High_M1[LineShow_D[i][1]]>escape1-(escape1-nowp)/3))
                   {
                      flag_escape1_3=1;
                      break;
                   }
               }
               if(flag_escape1_3==1)
               {
                  dis=LineShow_D[i][0]-LineShow_D[i][1];
                  if(dis!=0)
                  {
                     div=High_M1[LineShow_D[i][0]]-High_M1[LineShow_D[i][1]];
                     breakP1=div*(barsnum_M1-1-LineShow_D[i][0])/dis+High_M1[LineShow_D[i][0]];
                     kuan=div*(LineShow_D[i][2]-LineShow_D[i][0])/dis+High_M1[LineShow_D[i][0]]-Low_M1[LineShow_D[i][2]];
                     if(nowp>breakP1-kuan/10)
                     {
                        fsell(0,vol_full/2);
                        closeby_buy();
                        Alert("没赚15点出一半");
                        ObjectDelete(0,"escapeS");
                        ObjectDelete(0,"escapeSt");
                        ObjectDelete(0,"escape1");
                        ObjectDelete(0,"escape1t");
                        ObjectDelete(0,"estime_po");
                        return;
                     }
                  }
               }
           }
        }
        if((ObjectGetString(0,"escape_mode",OBJPROP_TEXT,0)=="1")&&(flag_vol==1))//赚15点，破3-4出一半
        {
            for(i=0;i<tlines_U;i++)
            {
                if((LineShow_U[i][1]<point3_pos)||(Low_M1[LineShow_U[i][1]]<point3+(nowp-point3)/3))
                break;
            }
            if(i<tlines_U)dis=LineShow_U[i][0]-LineShow_U[i][1];
            else dis=0;
            if(dis!=0)
            {
               div=Low_M1[LineShow_U[i][0]]-Low_M1[LineShow_U[i][1]];
               breakP1=div*(barsnum_M1-1-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
               breakP3=div*(barsnum_M1-3-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
               breakP4=div*(barsnum_M1-4-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
               if(nowp<breakP1-50*d_point)
               {
                  fsell(0,vol_full/2);
                  closeby_buy();
                  Alert("赚15点，破3-4出一半");
                  return;
               }
               if(Low_M1[barsnum_M1-3]<breakP3-5*d_point)
               {
                  if((nowp<Low_M1[barsnum_M1-2]-5*d_point)&&(Low_M1[barsnum_M1-2]<Low_M1[barsnum_M1-3])&&(Low_M1[barsnum_M1-4]>=breakP4))
                  {
                      fsell(0,vol_full/2);
                      closeby_buy();
                      Alert("赚15点，破3-4出一半");
                      return; 
                  }
               }
           }
        }
        if((flag_vol==1)&&(ObjectGetString(0,"escape_mode",OBJPROP_TEXT,0)=="2"))//25点以上
        {
           if(profit>vol_full*500)
           {
              SL=PositionGetDouble(POSITION_PRICE_OPEN);
              if(sl>SL)trade.PositionModify(_Symbol,SL,0);
           }
           if(ObjectGetString(0,"escapeS",OBJPROP_TEXT,0)!="2")//破通道出1和S
           {
              for(i=0;i<tlines_U-1;i++)
              {
                  dis=LineShow_U[i][0]-LineShow_U[i][1];
                  if(dis!=0)
                  {
                     div=Low_M1[LineShow_U[i][0]]-Low_M1[LineShow_U[i][1]];
                     breakP1=div*(barsnum_M1-1-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                     dis=LineShow_U[i+1][0]-LineShow_U[i+1][1];
                     if(dis!=0)
                     {
                        div=Low_M1[LineShow_U[i+1][0]]-Low_M1[LineShow_U[i+1][1]];
                        breakP11=div*(barsnum_M1-1-LineShow_U[i+1][0])/dis+Low_M1[LineShow_U[i+1][0]];
                        if(breakP1-breakP11>200*d_point)break;
                     }
                     else break;
                  }
              }
              if(i<tlines_U)dis=LineShow_U[i][0]-LineShow_U[i][1];
              else dis=0;
              if(dis!=0)
              {
                 div=Low_M1[LineShow_U[i][0]]-Low_M1[LineShow_U[i][1]];
                 breakP1=div*(barsnum_M1-1-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                 breakP3=div*(barsnum_M1-3-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                 breakP4=div*(barsnum_M1-4-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                 if(nowp<breakP1-50*d_point)
                 {
                    ObjectSetString(0,"escapeS",OBJPROP_TEXT,"2");
                    if(ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]]<ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]])
                    {
                       zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
                       time1=Time_M5[ZigZagBuffer_pos_M5[2]];
                    }
                    else
                    {
                        zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
                        time1=Time_M5[ZigZagBuffer_pos_M5[1]];
                    }
                    escape1_=DoubleToString(zig1,8);
                    ObjectCreate(0,"escapeSt",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                    ObjectSetString(0,"escape1",OBJPROP_TEXT,escape1_);
                    ObjectCreate(0,"escape1t",OBJ_ARROW_THUMB_UP,0,time1,zig1);
                    time1_=TimeToString(Time_M5[barsnum_M5-1]);
                    ObjectSetString(0,"estime_po",OBJPROP_TEXT,time1_);
                    return;
                 }
                 if(Low_M1[barsnum_M1-3]<breakP3-5*d_point)
                 {
                    if((nowp<Low_M1[barsnum_M1-2]-5*d_point)&&(Low_M1[barsnum_M1-2]<Low_M1[barsnum_M1-3])&&(Low_M1[barsnum_M1-4]>=breakP4))
                    {
                       ObjectSetString(0,"escapeS",OBJPROP_TEXT,"2");
                       if(ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]]<ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]])
                       {
                          zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
                          time1=Time_M5[ZigZagBuffer_pos_M5[2]];
                       }
                       else
                       {
                           zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
                           time1=Time_M5[ZigZagBuffer_pos_M5[1]];
                       }
                       escape1_=DoubleToString(zig1,8);
                       ObjectCreate(0,"escapeSt",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                       ObjectSetString(0,"escape1",OBJPROP_TEXT,escape1_);
                       ObjectCreate(0,"escape1t",OBJ_ARROW_THUMB_UP,0,time1,zig1);
                       time1_=TimeToString(Time_M5[barsnum_M5-1]);
                       ObjectSetString(0,"estime_po",OBJPROP_TEXT,time1_);
                       return;
                    }
                 }
              }
           }
           if(ObjectGetString(0,"escapeS",OBJPROP_TEXT,0)=="1")
           {
              ObjectDelete(0,"escapeS");
              ObjectDelete(0,"escapeSt");
              ObjectDelete(0,"estime_po");
              ObjectDelete(0,"escape1");
              ObjectDelete(0,"escape1t");
              ObjectDelete(0,"escape2");
              ObjectDelete(0,"escape2t");
              return;
           }
           if(ObjectGetString(0,"escapeS",OBJPROP_TEXT,0)=="2")
           {
              if(ObjectGetString(0,"escape2",OBJPROP_TEXT,0)=="0")
              {
                 escape1=StringToDouble(ObjectGetString(0,"escape1",OBJPROP_TEXT,0));
                 time1=StringToTime(ObjectGetString(0,"estime_po",OBJPROP_TEXT,0));
                 if(nowp>escape1)
                 {
                    ObjectSetString(0,"escape2",OBJPROP_TEXT,"A");//代表打破1点
                    return;
                 }
                 zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
                 zig2=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
                 time2=Time_M5[ZigZagBuffer_pos_M5[2]];
                 if((zig1>zig2)&&(time2>=time1))
                 {
                    escape2_=DoubleToString(zig2,8);
                    ObjectSetString(0,"escape2",OBJPROP_TEXT,escape2_);
                    ObjectCreate(0,"escape2t",OBJ_ARROW_THUMB_UP,0,time2,zig2);
                    return;
                 }
             }
             else
             {
                 if(ObjectGetString(0,"escape2",OBJPROP_TEXT,0)=="A")//破最小的通道出
                 {
                    if(ObjectGetString(0,"beforeS_2",OBJPROP_TEXT,0)=="0")
                    {
                       i=0;
                       if(i<tlines_U)dis=LineShow_U[i][0]-LineShow_U[i][1];
                       else dis=0;
                       if(dis!=0)
                       {
                          div=Low_M1[LineShow_U[i][0]]-Low_M1[LineShow_U[i][1]];
                          breakP1=div*(barsnum_M1-1-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                          breakP3=div*(barsnum_M1-3-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                          breakP4=div*(barsnum_M1-4-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                          if(nowp<breakP1-50*d_point)
                          {
                             timeS_2_=TimeToString(Time_M5[barsnum_M5-1]);
                             escape1_2=High_M1[iHighest(High_M1,barsnum_M1-LineShow_U[i][1],barsnum_M1-1)];
                             escape1_2_=DoubleToString(escape1_2,8);
                             ObjectSetString(0,"beforeS_2",OBJPROP_TEXT,timeS_2_);
                             ObjectSetString(0,"escape1_2",OBJPROP_TEXT,escape1_2_);
                             ObjectCreate(0,"escapeS_2t",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                             return;
                          }
                          if(Low_M1[barsnum_M1-3]<breakP3-5*d_point)
                          {
                             if((nowp<Low_M1[barsnum_M1-2]-5*d_point)&&(Low_M1[barsnum_M1-2]<Low_M1[barsnum_M1-3])&&(Low_M1[barsnum_M1-4]>=breakP4))
                             {
                                timeS_2_=TimeToString(Time_M5[barsnum_M5-1]);
                                escape1_2=High_M1[iHighest(High_M1,barsnum_M1-LineShow_U[i][1],barsnum_M1-1)];
                                escape1_2_=DoubleToString(escape1_2,8);
                                ObjectSetString(0,"beforeS_2",OBJPROP_TEXT,timeS_2_);
                                ObjectSetString(0,"escape1_2",OBJPROP_TEXT,escape1_2_);
                                ObjectCreate(0,"escapeS_2t",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                                return;
                             }
                          }
                       }
                    }
                    else
                    {
                        escape1_2=StringToDouble(ObjectGetString(0,"escape1_2",OBJPROP_TEXT,0));
                        if(nowp>escape1_2)
                        {
                           ObjectDelete(0,"beforeS_2");
                           ObjectDelete(0,"escape1_2");
                           ObjectDelete(0,"escapeS_2t");
                           ObjectDelete(0,"escape2_2");
                           ObjectDelete(0,"escape2_2t");
                           return;
                        }
                        if(ObjectGetString(0,"escape2_2",OBJPROP_TEXT,0)=="0")
                        {
                           escape2_2_=DoubleToString(nowp,8);
                           ObjectSetString(0,"escape2_2",OBJPROP_TEXT,escape2_2_);
                           ObjectCreate(0,"escape2_2t",OBJ_ARROW_THUMB_UP,0,Time_M5[barsnum_M5-1],nowp);
                           return;
                        }
                        else
                        {
                           escape2_2=StringToDouble(ObjectGetString(0,"escape2_2",OBJPROP_TEXT,0));
                           timeS_2=StringToTime(ObjectGetString(0,"beforeS_2",OBJPROP_TEXT,0));
                           if(Time_M5[barsnum_M5-2]>timeS_2)
                           {
                              if(Low_M5[barsnum_M5-2]<escape2_2)
                              {
                                 escape2_2_=DoubleToString(Low_M5[barsnum_M5-2],8);
                                 ObjectSetString(0,"escape2_2",OBJPROP_TEXT,escape2_2_);
                                 ObjectSetDouble(0,"escape2_2t",OBJPROP_PRICE,Low_M5[barsnum_M5-2]);
                                 ObjectSetInteger(0,"escape2_2t",OBJPROP_TIME,Time_M5[barsnum_M5-2]);
                                 return;
                              }
                              if((Low_M5[barsnum_M5-2]>=escape2_2)&&(nowp<escape2_2))
                              {
                                 fsell(0,vol_full/2);
                                 closeby_buy();
                                 ObjectDelete(0,"escape_mode");
                                 ObjectDelete(0,"escapeS");
                                 ObjectDelete(0,"escapeSt");
                                 ObjectDelete(0,"estime_po");
                                 ObjectDelete(0,"escape1");
                                 ObjectDelete(0,"escape1t");
                                 ObjectDelete(0,"escape2");
                                 ObjectDelete(0,"escape2t");
                                 ObjectDelete(0,"beforeS_2");
                                 ObjectDelete(0,"escape1_2");
                                 ObjectDelete(0,"escapeS_2t");
                                 ObjectDelete(0,"escape2_2");
                                 ObjectDelete(0,"escape2_2t");
                                 Alert("25点以上左侧+123出场");
                                 return;
                              }
                           }
                        }
                    }
                 }
                 else//等下来以后破最小的通道出
                 {
                     escape1=StringToDouble(ObjectGetString(0,"escape1",OBJPROP_TEXT,0));
                     time1=StringToTime(ObjectGetString(0,"estime_po",OBJPROP_TEXT,0));
                     if(nowp>escape1)
                     {
                        ObjectSetString(0,"escape2",OBJPROP_TEXT,"A");//代表打破1点
                        return;
                     }
                     escape2=StringToDouble(ObjectGetString(0,"escape2",OBJPROP_TEXT,0));
                     zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
                     zig2=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
                     time2=Time_M5[ZigZagBuffer_pos_M5[2]];
                     escape2_time=ObjectGetInteger(0,"escape2t",OBJPROP_TIME,0);
                     if((zig1<zig2)&&(time2>=escape2_time))
                     {
                        close_buy();
                        Alert("25点以上，123全出");
                        ObjectsDeleteAll(0,0,OBJ_ARROW_THUMB_UP);
                        ObjectsDeleteAll(0,0,OBJ_LABEL);
                        return;
                     }
                  }
              }
           }
        }
     }
     if((ObjectGetString(0,"escape_ag",OBJPROP_TEXT,0)!="0")&&(flag_vol==1))//接过单,破接单之前的通道123出一半，(或者破外面的通道直接全出)
     {
         price_ag=StringToDouble(ObjectGetString(0,"price_ag",OBJPROP_TEXT,0));
         time_ag=StringToTime(ObjectGetString(0,"escape_ag",OBJPROP_TEXT,0));
         if(ObjectGetString(0,"escape_mode",OBJPROP_TEXT,0)!="2")
         {
            if(nowp-price_ag>=250*d_point)ObjectSetString(0,"escape_mode",OBJPROP_TEXT,"2");
            else ObjectSetString(0,"escape_mode",OBJPROP_TEXT,"1");
         }
         if(ObjectGetString(0,"escape_mode",OBJPROP_TEXT,0)=="0")
         {
            i=0;
            if(i<tlines_U)dis=LineShow_U[i][0]-LineShow_U[i][1];
            else dis=0;
            if(dis!=0)
            {
               div=Low_M1[LineShow_U[i][0]]-Low_M1[LineShow_U[i][1]];
               breakP1=div*(barsnum_M1-1-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
               breakP3=div*(barsnum_M1-3-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
               breakP4=div*(barsnum_M1-4-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
               if(nowp<breakP1-70*d_point)
               {
                  fsell(0,vol_full/2);
                  closeby_buy();
                  Alert("接单后亏损，破最小通路出一半");
                  return;
               }
               if(Low_M1[barsnum_M1-3]<breakP3-5*d_point)
               {
                  if((nowp<Low_M1[barsnum_M1-2]-5*d_point)&&(Low_M1[barsnum_M1-2]<Low_M1[barsnum_M1-3])&&(Low_M1[barsnum_M1-4]>=breakP4))
                  {
                     fsell(0,vol_full/2);
                     closeby_buy();
                     Alert("接单后亏损，破最小通路出一半");
                     return; 
                  }
               }
            }
         }
         if(ObjectGetString(0,"escape_mode",OBJPROP_TEXT,0)=="1")
         {
            for(i=0;i<tlines_U;i++)
            {
                if((LineShow_U[i][1]<point3_pos)||(Low_M1[LineShow_U[i][1]]<point3+(nowp-point3)/3))
                break;
            }
            if(i<tlines_U)dis=LineShow_U[i][0]-LineShow_U[i][1];
            else dis=0;
            if(dis!=0)
            {
               div=Low_M1[LineShow_U[i][0]]-Low_M1[LineShow_U[i][1]];
               breakP1=div*(barsnum_M1-1-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
               breakP3=div*(barsnum_M1-3-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
               breakP4=div*(barsnum_M1-4-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
               if(nowp<breakP1-50*d_point)
               {
                  fsell(0,vol_full/2);
                  closeby_buy();
                  Alert("接单后，破3-4出一半");
                  return;
               }
               if(Low_M1[barsnum_M1-3]<breakP3-5*d_point)
               {
                  if((nowp<Low_M1[barsnum_M1-2]-5*d_point)&&(Low_M1[barsnum_M1-2]<Low_M1[barsnum_M1-3])&&(Low_M1[barsnum_M1-4]>=breakP4))
                  {
                     fsell(0,vol_full/2);
                     closeby_buy();
                     Alert("接单后，破3-4出一半");
                     return; 
                  }
               }
            }
         }
         if(ObjectGetString(0,"escape_mode",OBJPROP_TEXT,0)=="2")
         {
            if(ObjectGetString(0,"escape",OBJPROP_TEXT,0)=="0")
            {
               time_ag=StringToTime(ObjectGetString(0,"escape_ag",OBJPROP_TEXT,0));
               for(i=0;i<tlines_U;i++)
               {
                   if(Time_M1[LineShow_U[i][1]]<time_ag)break;
               }
               if((middle_TL>0)&&(middle_TL-1<i))i=middle_TL-1;
               if(i<tlines_U)dis=LineShow_U[i][0]-LineShow_U[i][1];
               else dis=0;
               if(dis!=0)
               {
                  div=Low_M1[LineShow_U[i][0]]-Low_M1[LineShow_U[i][1]];
                  breakP1=div*(barsnum_M1-1-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                  breakP3=div*(barsnum_M1-3-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                  breakP4=div*(barsnum_M1-4-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                  if(nowp<breakP1-50*d_point)
                  {
                     ObjectSetString(0,"escape",OBJPROP_TEXT,"1");
                     if(i==middle_TL-1)
                        ObjectSetString(0,"escape",OBJPROP_TEXT,"2");
                     escapeS_=DoubleToString(breakP1,8);
                     ObjectSetString(0,"escapeS",OBJPROP_TEXT,escapeS_);
                     if(ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]]<ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]])
                     {
                        zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
                        time1=Time_M5[ZigZagBuffer_pos_M5[2]];
                     }
                     else
                     {
                         zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
                         time1=Time_M5[ZigZagBuffer_pos_M5[1]];
                     }
                     escape1_=DoubleToString(zig1,8);
                     ObjectCreate(0,"escapeSt",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                     ObjectSetString(0,"escape1",OBJPROP_TEXT,escape1_);
                     ObjectCreate(0,"escape1t",OBJ_ARROW_THUMB_UP,0,time1,zig1);
                     time1_=TimeToString(Time_M5[barsnum_M5-1]);
                     ObjectSetString(0,"estime_po",OBJPROP_TEXT,time1_);
                     return;
                  }
                  if(Low_M1[barsnum_M1-3]<breakP3-5*d_point)
                  {
                     if((nowp<Low_M1[barsnum_M1-2]-5*d_point)&&(Low_M1[barsnum_M1-2]<Low_M1[barsnum_M1-3])&&(Low_M1[barsnum_M1-4]>=breakP4))
                     {
                        ObjectSetString(0,"escape",OBJPROP_TEXT,"1");
                        if(i==middle_TL-1)
                           ObjectSetString(0,"escape",OBJPROP_TEXT,"2");
                        escapeS_=DoubleToString(breakP1,8);
                        ObjectSetString(0,"escapeS",OBJPROP_TEXT,escapeS_);
                        if(ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]]<ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]])
                        {
                           zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
                           time1=Time_M5[ZigZagBuffer_pos_M5[2]];
                        }
                        else
                        {
                            zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
                            time1=Time_M5[ZigZagBuffer_pos_M5[1]];
                        }
                        escape1_=DoubleToString(zig1,8);
                        ObjectCreate(0,"escapeSt",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                        ObjectSetString(0,"escape1",OBJPROP_TEXT,escape1_);
                        ObjectCreate(0,"escape1t",OBJ_ARROW_THUMB_UP,0,time1,zig1);
                        time1_=TimeToString(Time_M5[barsnum_M5-1]);
                        ObjectSetString(0,"estime_po",OBJPROP_TEXT,time1_);
                        return;
                    }
                  }
               }
            }
            else
            {
                escapeS=StringToDouble(ObjectGetString(0,"escapeS",OBJPROP_TEXT,0));
                escape1=StringToDouble(ObjectGetString(0,"escape1",OBJPROP_TEXT,0));
                estime=StringToTime(ObjectGetString(0,"estime_po",OBJPROP_TEXT,0));
                if(nowp>escape1)
                {
                   ObjectDelete(0,"escape");
                   ObjectDelete(0,"escapeS");
                   ObjectDelete(0,"escapeSt");
                   ObjectDelete(0,"estime_po");
                   ObjectDelete(0,"escape1");
                   ObjectDelete(0,"escape1t");
                   ObjectDelete(0,"escape2");
                   ObjectDelete(0,"escape2t");
                   ObjectDelete(0,"escapeS_2to3");
                   ObjectDelete(0,"escape1_2to3");
                   ObjectDelete(0,"escapeS_2to3t");
                   ObjectDelete(0,"escape2_2to3");
                   ObjectDelete(0,"escape2_2to3t");
                   return;
                }
                if(ObjectGetString(0,"escape2",OBJPROP_TEXT,0)=="0")
                {
                   zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
                   zig2=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
                   time2=Time_M5[ZigZagBuffer_pos_M5[2]];
                   if((zig1>zig2)&&(time2>=estime))
                   {
                     point2_=DoubleToString(zig2,8);
                     ObjectSetString(0,"escape2",OBJPROP_TEXT,point2_);
                     ObjectCreate(0,"escape2t",OBJ_ARROW_THUMB_UP,0,time2,zig2);
                     return;
                   }
                }
                else
                {
                    if(ObjectGetString(0,"escape",OBJPROP_TEXT,0)=="1")vol_now=vol_full/2;
                    if(ObjectGetString(0,"escape",OBJPROP_TEXT,0)=="2")vol_now=vol_full;
                    escape2=StringToDouble(ObjectGetString(0,"escape2",OBJPROP_TEXT,0));
                    zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
                    zig2=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
                    time3=Time_M5[ZigZagBuffer_pos_M5[2]+2];
                    int flag_2to3=0;
                    for(i=0;i<tlines_U;i++)
                    {
                        if((Time_M1[LineShow_U[i][1]]>estime)&&(Low_M1[LineShow_U[i][1]]<escape2+(nowp-escape2)/3))
                        {
                           flag_2to3=1; 
                           break;
                        }
                    }
                    if(ObjectGetString(0,"escapeS_2to3",OBJPROP_TEXT,0)=="0")
                    {
                       if((flag_2to3==1)&&(i<tlines_U))
                       {
                          dis=LineShow_U[i][0]-LineShow_U[i][1];
                          if(dis!=0)
                          {
                             div=Low_M1[LineShow_U[i][0]]-Low_M1[LineShow_U[i][1]];
                             breakP1=div*(barsnum_M1-1-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                             breakP3=div*(barsnum_M1-3-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                             breakP4=div*(barsnum_M1-4-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                          }
                          if(nowp<breakP1-50*d_point)
                          {
                             timeS_2to3_=TimeToString(Time_M5[barsnum_M5-1]);
                             escape1_2to3=High_M1[iHighest(High_M1,barsnum_M1-LineShow_U[i][1],barsnum_M1-1)];
                             escape1_2to3_=DoubleToString(escape1_2to3,8);
                             ObjectSetString(0,"escapeS_2to3",OBJPROP_TEXT,timeS_2to3_);
                             ObjectSetString(0,"escape1_2to3",OBJPROP_TEXT,escape1_2to3_);
                             ObjectCreate(0,"escapeS_2to3t",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                             return;
                          }
                          if(Low_M1[barsnum_M1-3]<breakP3-5*d_point)
                          {
                             if((nowp<Low_M1[barsnum_M1-2]-5*d_point)&&(Low_M1[barsnum_M1-2]<Low_M1[barsnum_M1-3])&&(Low_M1[barsnum_M1-4]>=breakP4))
                             {
                                  timeS_2to3_=TimeToString(Time_M5[barsnum_M5-1]);
                                  escape1_2to3=High_M1[iHighest(High_M1,barsnum_M1-LineShow_U[i][1],barsnum_M1-1)];
                                  escape1_2to3_=DoubleToString(escape1_2to3,8);
                                  ObjectSetString(0,"escapeS_2to3",OBJPROP_TEXT,timeS_2to3_);
                                  ObjectSetString(0,"escape1_2to3",OBJPROP_TEXT,escape1_2to3_);
                                  ObjectCreate(0,"escapeS_2to3t",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                                  return;
                              }
                          }
                       }
                    }
                    else
                    {
                        escape1_2to3=StringToDouble(ObjectGetString(0,"escape1_2to3",OBJPROP_TEXT,0));
                        if(nowp>escape1_2to3)
                        {
                           ObjectDelete(0,"escapeS_2to3");
                           ObjectDelete(0,"escape1_2to3");
                           ObjectDelete(0,"escapeS_2to3t");
                           ObjectDelete(0,"escape2_2to3");
                           ObjectDelete(0,"escape2_2to3t");
                           return;
                        }
                        if(ObjectGetString(0,"escape2_2to3",OBJPROP_TEXT,0)=="0")
                        {
                           escape2_2to3_=DoubleToString(nowp,8);
                           ObjectSetString(0,"escape2_2to3",OBJPROP_TEXT,escape2_2to3_);
                           ObjectCreate(0,"escape2_2to3t",OBJ_ARROW_THUMB_UP,0,Time_M5[barsnum_M5-1],nowp);
                           return;
                        }
                       else
                       {
                            escape2_2to3=StringToDouble(ObjectGetString(0,"escape2_2to3",OBJPROP_TEXT,0));
                            timeS_2to3=StringToTime(ObjectGetString(0,"escapeS_2to3",OBJPROP_TEXT,0));
                            if(Time_M5[barsnum_M5-2]>timeS_2to3)
                            {
                               if(Low_M5[barsnum_M5-2]<escape2_2to3)
                               {
                                  escape2_2to3_=DoubleToString(Low_M5[barsnum_M5-2],8);
                                  ObjectSetString(0,"escape2_2to3",OBJPROP_TEXT,escape2_2to3_);
                                  ObjectSetDouble(0,"escape2_2to3t",OBJPROP_PRICE,Low_M5[barsnum_M5-2]);
                                  ObjectSetInteger(0,"escape2_2to3t",OBJPROP_TIME,Time_M5[barsnum_M5-2]);
                                  return;
                               }
                               if((Low_M5[barsnum_M5-2]>=escape2_2to3)&&(nowp<escape2_2to3))
                               {
                                  close_buy();
                                  Alert("接单以后破中通道2次123全出");
                                  ObjectDelete(0,"escape");
                                  ObjectDelete(0,"escapeS");
                                  ObjectDelete(0,"escapeSt");
                                  ObjectDelete(0,"estime_po");
                                  ObjectDelete(0,"escape1");
                                  ObjectDelete(0,"escape1t");
                                  ObjectDelete(0,"escape2");
                                  ObjectDelete(0,"escape2t");
                                  ObjectDelete(0,"escapeS_2to3");
                                  ObjectDelete(0,"escapeS_2to3t");
                                  ObjectDelete(0,"escape2_2to3");
                                  ObjectDelete(0,"escape2_2to3t");
                                  return;
                               }
                            }
                        }
                    }
                    if((zig1<zig2)&&(time3>=estime)&&(nowp<escapeS))
                    {
                       close_buy();
                       Alert("接单以后破通道123全出，Z字线123");
                       ObjectDelete(0,"escape");
                       ObjectDelete(0,"escapeS");
                       ObjectDelete(0,"escapeSt");
                       ObjectDelete(0,"estime_po");
                       ObjectDelete(0,"escape1");
                       ObjectDelete(0,"escape1t");
                       ObjectDelete(0,"escape2");
                       ObjectDelete(0,"escape2t");
                       ObjectDelete(0,"escapeS_2to3");
                       ObjectDelete(0,"escapeS_2to3t");
                       ObjectDelete(0,"escape2_2to3");
                       ObjectDelete(0,"escape2_2to3t");
                       return;
                    }
                }
            }
        }
     }
     if(flag_vol==2)
     {
        i=barsnum_M1-1;
        while((Time_M1[i]>deal_time)&&(Time_M1[i]>Time_D1[barsnum_D1-10]))
        {
              i--;
        }
        int pointh_pos=iHighest(High_M1,barsnum_M1-i,barsnum_M1-5);
        double pointh=High_M1[pointh_pos];
        double pointl;
        if(ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]]<ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]])
           pointl=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
        else pointl=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
        if(nowp>pointh)
        {
           time_ag_=TimeToString(Time_M5[barsnum_M5-1]);
           ObjectSetString(0,"escape_ag",OBJPROP_TEXT,time_ag_);
           price_ag_=DoubleToString(pointl,8);
           ObjectSetString(0,"price_ag",OBJPROP_TEXT,price_ag_);
           fbuy(sl,vol_full/2);
           Alert("接一半");
           ObjectDelete(0,"escape_mode");
           ObjectDelete(0,"escapeS");
           ObjectDelete(0,"escapeSt");
           ObjectDelete(0,"estime_po");
           ObjectDelete(0,"escape1");
           ObjectDelete(0,"escape1t");
           ObjectDelete(0,"escape2");
           ObjectDelete(0,"escape2t");
           return;
        }
        if(ObjectGetString(0,"escape1_2to3",OBJPROP_TEXT,0)!="0")
        {
           escape1_2to3=StringToDouble(ObjectGetString(0,"escape1_2to3",OBJPROP_TEXT,0));
           if(nowp>escape1_2to3)
           {
              time_ag_=TimeToString(Time_M5[barsnum_M5-1]);
              ObjectSetString(0,"escape_ag",OBJPROP_TEXT,time_ag_);
              price_ag_=DoubleToString(pointl,8);
              ObjectSetString(0,"price_ag",OBJPROP_TEXT,price_ag_);
              fbuy(sl,vol_full/2);
              Alert("双123的接单");
              ObjectDelete(0,"escape_mode");
              ObjectDelete(0,"escapeS");
              ObjectDelete(0,"escapeSt");
              ObjectDelete(0,"estime_po");
              ObjectDelete(0,"escape1");
              ObjectDelete(0,"escape1t");
              ObjectDelete(0,"escape2");
              ObjectDelete(0,"escape2t");
              ObjectDelete(0,"escape1_2to3");
              return;
           }
        }
        if(ObjectGetString(0,"escapeS",OBJPROP_TEXT,0)=="0")
        {
           for(i=0;i<tlines_U-1;i++)
           {
               dis=LineShow_U[i][0]-LineShow_U[i][1];
               if(dis!=0)
               {
                  div=Low_M1[LineShow_U[i][0]]-Low_M1[LineShow_U[i][1]];
                  breakP1=div*(barsnum_M1-1-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                  dis=LineShow_U[i+1][0]-LineShow_U[i+1][1];
                  if(dis!=0)
                  {
                     div=Low_M1[LineShow_U[i+1][0]]-Low_M1[LineShow_U[i+1][1]];
                     breakP11=div*(barsnum_M1-1-LineShow_U[i+1][0])/dis+Low_M1[LineShow_U[i+1][0]];
                     if(breakP1-breakP11>200*d_point)break;
                  }
                  else break;
               }
           }
           if(big_TL>0)
           {
              datetime nowtime=SymbolInfoInteger(_Symbol,SYMBOL_TIME);//当前时间
              HistorySelect(Time_H4[barsnum_H4-60],nowtime);
              int order_num=HistoryOrdersTotal();//选择的历史区间内总交易次数
              int ticket=HistoryOrderGetTicket(order_num-1);//这是选择订单的ticket
              datetime last_deal_time=HistoryOrderGetInteger(ticket,ORDER_TIME_DONE);
              if(HistoryOrderGetInteger(ticket,ORDER_TYPE)==ORDER_TYPE_SELL)
              {
                 for(i=0;i<tlines_U;i++)
                 {
                     if(Time_M1[LineShow_U[i][1]]<last_deal_time)break;
                 }
              }
           }
           if(i<tlines_U)dis=LineShow_U[i][0]-LineShow_U[i][1];
           else dis=0;
           if(dis!=0)
           {
              div=Low_M1[LineShow_U[i][0]]-Low_M1[LineShow_U[i][1]];
              breakP1=div*(barsnum_M1-1-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
              breakP3=div*(barsnum_M1-3-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
              breakP4=div*(barsnum_M1-4-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
              if(nowp<breakP1-50*d_point)
              {
                 escapeS_=DoubleToString(breakP1,8);
                 ObjectSetString(0,"escapeS",OBJPROP_TEXT,escapeS_);
                 ObjectCreate(0,"escapeSt",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                 findperiod2();
                 return;
              }
              if(Low_M1[barsnum_M1-3]<breakP3-5*d_point)
              {
                 if((nowp<Low_M1[barsnum_M1-2]-5*d_point)&&(Low_M1[barsnum_M1-2]<Low_M1[barsnum_M1-3])&&(Low_M1[barsnum_M1-4]>=breakP4))
                 {
                    escapeS_=DoubleToString(breakP1,8);
                    ObjectSetString(0,"escapeS",OBJPROP_TEXT,escapeS_);
                    ObjectCreate(0,"escapeSt",OBJ_ARROW_THUMB_UP,0,Time_M1[barsnum_M1-1],breakP1);
                    findperiod2();
                    return;
                 }
              }
           }
        }
        else
        {
            escapeS=StringToDouble(ObjectGetString(0,"escapeS",OBJPROP_TEXT,0));
            escape1=StringToDouble(ObjectGetString(0,"escape1",OBJPROP_TEXT,0));
            estime=StringToTime(ObjectGetString(0,"estime_po",OBJPROP_TEXT,0));
            period=StringToInteger(ObjectGetString(0,"trade_period",OBJPROP_TEXT,0));
            if((nowp<escapeS-(escape1-escapeS)/3*2)&&(escape1-escapeS>200*d_point)&&(big_TL<0))
            {
               close_buy();
               Alert("2/3出剩下一半");
               ObjectsDeleteAll(0,0,OBJ_ARROW_THUMB_UP);
               ObjectsDeleteAll(0,0,OBJ_LABEL);
               return;
            }
            if(ObjectGetString(0,"escape2",OBJPROP_TEXT,0)=="0")
            {
               if(nowp>escape1)
               {
                  ObjectDelete(0,"escape1");
                  ObjectDelete(0,"escape1t");
                  ObjectDelete(0,"escapeS");
                  ObjectDelete(0,"escapeSt");
                  return;
               }
               if(period==2)
               {
                  zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
                  zig2=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
                  time2=Time_M5[ZigZagBuffer_pos_M5[2]];
               }
               if(period==3)
               {
                  zig1=ZigZagBuffer_M15[ZigZagBuffer_pos_M15[1]];
                  zig2=ZigZagBuffer_M15[ZigZagBuffer_pos_M15[2]];
                  time2=Time_M15[ZigZagBuffer_pos_M15[2]];
               }
               if((zig1>zig2)&&(time2>=estime))
               {
                  point2_=DoubleToString(zig2,8);
                  ObjectSetString(0,"escape2",OBJPROP_TEXT,point2_);
                  ObjectCreate(0,"escape2t",OBJ_ARROW_THUMB_UP,0,time2,zig2);
                  return;
               }
            }
            else
            {
                if(nowp>escape1)
                {
                   ObjectDelete(0,"escape1");
                   ObjectDelete(0,"escape1t");
                   ObjectDelete(0,"escapeS");
                   ObjectDelete(0,"escapeSt");
                   ObjectDelete(0,"escape2");
                   ObjectDelete(0,"escape2t");
                   return;
                }
                escape2=StringToDouble(ObjectGetString(0,"escape2",OBJPROP_TEXT,0));
                zig1=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]];
                zig2=ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]];
                time3=Time_M5[ZigZagBuffer_pos_M5[2]+2];
                int flag_2to3=0;
                for(i=0;i<tlines_U;i++)
                {
                    if((Time_M1[LineShow_U[i][1]]>estime)&&(Low_M1[LineShow_U[i][1]]<escape2+(nowp-escape2)/3))
                    {
                       flag_2to3=1; 
                       break;
                    }
                }
                if((flag_2to3==1)&&(i<tlines_D))
                {
                   dis=LineShow_U[i][0]-LineShow_U[i][1];
                   if(dis!=0)
                   {
                      div=Low_M1[LineShow_U[i][0]]-Low_M1[LineShow_U[i][1]];
                      breakP1=div*(barsnum_M1-1-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                      breakP3=div*(barsnum_M1-3-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                      breakP4=div*(barsnum_M1-4-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
                      if(nowp<breakP1-50*d_point)
                      {
                         close_buy();
                         Alert("123出剩下一半");
                         ObjectsDeleteAll(0,0,OBJ_ARROW_THUMB_UP);
                         ObjectsDeleteAll(0,0,OBJ_LABEL);
                         return;
                      }
                      if(Low_M1[barsnum_M1-3]<breakP3-5*d_point)
                      {
                         if((nowp<Low_M1[barsnum_M1-2]-5*d_point)&&(Low_M1[barsnum_M1-2]<Low_M1[barsnum_M1-3])&&(Low_M1[barsnum_M1-4]>=breakP4))
                         {
                              close_buy();
                              Alert("123出剩下一半");
                              ObjectsDeleteAll(0,0,OBJ_ARROW_THUMB_UP);
                              ObjectsDeleteAll(0,0,OBJ_LABEL);
                              return;
                          }
                      }
                   }
                }
                if((zig1<zig2)&&(time3>=estime)&&(nowp<escapeS))
                {
                   close_buy();
                   Alert("123出剩下一半");
                   ObjectsDeleteAll(0,0,OBJ_ARROW_THUMB_UP);
                   ObjectsDeleteAll(0,0,OBJ_LABEL);
                   return;
                }
            }
        }
     }
}

void wave()
{
     int i,j,dis;
     double div,breakP1,breakP3,breakP4,breakP11;
     double nowp=SymbolInfoDouble(_Symbol,SYMBOL_BID);
     datetime last_wave_time;
     double last_wave_price;
     double point1=0,point2=0,point3=0;
     datetime point1_time,point2_time,point3_time;
     datetime wave0_time,wave1_time,wave2_time,wave3_time;
     double L_lowest,L_highest;
     int L_lowest_pos,L_highest_pos;
     point1=StringToDouble(ObjectGetString(0,"point1",OBJPROP_TEXT,0));
     point2=StringToDouble(ObjectGetString(0,"point2",OBJPROP_TEXT,0));
     point3=StringToDouble(ObjectGetString(0,"point3",OBJPROP_TEXT,0));
     point1_time=ObjectGetInteger(0,"point1t",OBJPROP_TIME,0);
     point2_time=ObjectGetInteger(0,"point2t",OBJPROP_TIME,0);
     point3_time=ObjectGetInteger(0,"pointS_2to3t",OBJPROP_TIME,0);
     //波浪标记(1&2)
     if((ObjectFind(0,"wave0")<0)&&(point2!=0))
     {
        if(point2_time>Time_H1[barsnum_H1-5])
        {
           ObjectCreate(0,"wave0",OBJ_TEXT,0,point1_time,point1);
           ObjectSetString(0,"wave0",OBJPROP_TEXT,"[0]");
           ObjectCreate(0,"wave1",OBJ_TEXT,0,point2_time,point2+50*d_point);
           ObjectSetString(0,"wave1",OBJPROP_TEXT,"[1]");
           if((point3!=0)&&(point3_time>point2_time))
           {
              ObjectCreate(0,"wave2",OBJ_TEXT,0,point3_time,point3);
              ObjectSetString(0,"wave2",OBJPROP_TEXT,"[2]");
           }
        }
     }
     
     if(ObjectFind(0,"wave0")>=0)
     {
        last_wave_price=ObjectGetDouble(0,"wave0",OBJPROP_PRICE,0);
        wave0_time=ObjectGetInteger(0,"wave0",OBJPROP_TIME,0);
        if(nowp<last_wave_price)
        {
           ObjectsDeleteAll(0,-1,OBJ_TEXT);
        }
        if(big_TL<0)
        {
           if(Time_M1[LineShow_U[-1*big_TL-1][1]]>wave0_time)
           {
              ObjectsDeleteAll(0,-1,OBJ_TEXT);
           }
        }
     }
     
     if(ObjectFind(0,"wave2")<0)
     {
        last_wave_price=ObjectGetDouble(0,"wave1",OBJPROP_PRICE,0)-50*d_point;
        if(nowp>last_wave_price)
        {
           ObjectSetInteger(0,"wave1",OBJPROP_TIME,Time_M1[barsnum_M1-1]);
           ObjectSetDouble(0,"wave1",OBJPROP_PRICE,nowp+50*d_point);
        }
        last_wave_time=ObjectGetInteger(0,"wave1",OBJPROP_TIME,0);
        last_wave_price=ObjectGetDouble(0,"wave1",OBJPROP_PRICE,0)-50*d_point;
        for(i=0;i<tlines_D;i++)
        {
            if((Time_M1[LineShow_D[i][1]-10]<last_wave_time)&&(High_M1[LineShow_D[i][1]]>last_wave_price)&&(last_wave_time<Time_M1[barsnum_M1-30]))
            break;
        }
        if(i<tlines_D)dis=LineShow_D[i][0]-LineShow_D[i][1];
        else dis=0;
        if(dis!=0)
        {
           div=High_M1[LineShow_D[i][0]]-High_M1[LineShow_D[i][1]];
           breakP1=div*(barsnum_M1-1-LineShow_D[i][0])/dis+High_M1[LineShow_D[i][0]];
           breakP3=div*(barsnum_M1-3-LineShow_D[i][0])/dis+High_M1[LineShow_D[i][0]];
           breakP4=div*(barsnum_M1-4-LineShow_D[i][0])/dis+High_M1[LineShow_D[i][0]];
           if(nowp>breakP1+50*d_point)
           {
              if(ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]]<ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]])
              {
                 if(Time_M5[ZigZagBuffer_pos_M5[1]]>last_wave_time)
                 {
                    ObjectCreate(0,"wave2",OBJ_TEXT,0,Time_M5[ZigZagBuffer_pos_M5[1]],ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]]);
                    ObjectSetString(0,"wave2",OBJPROP_TEXT,"[2]");
                 }
              }
              else 
              {
                  if(Time_M5[ZigZagBuffer_pos_M5[2]]>last_wave_time)
                  {
                     ObjectCreate(0,"wave2",OBJ_TEXT,0,Time_M5[ZigZagBuffer_pos_M5[2]],ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]]);
                     ObjectSetString(0,"wave2",OBJPROP_TEXT,"[2]");
                  }
              }
           }
           if(High_M1[barsnum_M1-3]>breakP3+5*d_point)
           {
              if((nowp>High_M1[barsnum_M1-2]+5*d_point)&&(High_M1[barsnum_M1-2]>High_M1[barsnum_M1-3])&&(High_M1[barsnum_M1-4]<=breakP4))
              {
                 if(ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]]<ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]])
                 {
                    if(Time_M5[ZigZagBuffer_pos_M5[1]]>last_wave_time)
                    {
                       ObjectCreate(0,"wave2",OBJ_TEXT,0,Time_M5[ZigZagBuffer_pos_M5[1]],ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]]+50*d_point);
                       ObjectSetString(0,"wave2",OBJPROP_TEXT,"[2]");
                    }
                 }
                 else 
                 {
                     if(Time_M5[ZigZagBuffer_pos_M5[2]]>last_wave_time)
                     {
                        ObjectCreate(0,"wave2",OBJ_TEXT,0,Time_M5[ZigZagBuffer_pos_M5[2]],ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]]+50*d_point);
                        ObjectSetString(0,"wave2",OBJPROP_TEXT,"[2]");
                     }
                 }
              }
           }
        }
     }
     //波浪标记(3)
     if((ObjectFind(0,"wave2")>=0)&&(ObjectFind(0,"wave3")<0))
     {
        last_wave_price=ObjectGetDouble(0,"wave2",OBJPROP_PRICE,0);
        wave1_time=ObjectGetInteger(0,"wave1",OBJPROP_TIME,0);
        if(nowp<last_wave_price)
        {
           ObjectSetInteger(0,"wave2",OBJPROP_TIME,Time_M1[barsnum_M1-1]);
           ObjectSetDouble(0,"wave2",OBJPROP_PRICE,nowp);
        }
        last_wave_time=ObjectGetInteger(0,"wave2",OBJPROP_TIME,0);
        last_wave_price=ObjectGetDouble(0,"wave2",OBJPROP_PRICE,0);
        for(i=0;i<tlines_U;i++)
        {
            if((Time_M1[LineShow_U[i][1]-10]<=last_wave_time)&&(Low_M1[LineShow_U[i][1]]<=last_wave_price)&&(last_wave_time<Time_M1[barsnum_M1-30]))
            break;
        }
        if(i<tlines_U)dis=LineShow_U[i][0]-LineShow_U[i][1];
        else dis=0;
        if(dis!=0)
        {
           div=Low_M1[LineShow_U[i][0]]-Low_M1[LineShow_U[i][1]];
           breakP1=div*(barsnum_M1-1-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
           breakP3=div*(barsnum_M1-3-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
           breakP4=div*(barsnum_M1-4-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
           if(nowp>ObjectGetDouble(0,"wave1",OBJPROP_PRICE,0))
           {
              L_highest=High_M1[LineShow_U[i][1]];
              L_highest_pos=LineShow_U[i][1];
              if(nowp<breakP1-50*d_point)
              {
                 for(j=LineShow_U[i][1];j<=barsnum_M1-1;j++)
                 {
                     if((High_M1[j]>L_highest)&&(Time_M1[j]>wave1_time))
                     {
                        L_highest=High_M1[j];
                        L_highest_pos=j;
                     }
                 }
                 ObjectCreate(0,"wave3",OBJ_TEXT,0,Time_M1[L_highest_pos],L_highest+50*d_point);
                 ObjectSetString(0,"wave3",OBJPROP_TEXT,"[3]");
              }
              if(High_M1[barsnum_M1-3]<breakP3-5*d_point)
              {
                 if((nowp<High_M1[barsnum_M1-2]-5*d_point)&&(High_M1[barsnum_M1-2]<High_M1[barsnum_M1-3])&&(High_M1[barsnum_M1-4]>=breakP4))
                 {
                    for(j=LineShow_U[i][1];j<=barsnum_M1-1;j++)
                    {
                        if((High_M1[j]>L_highest)&&(Time_M1[j]>wave1_time))
                        {
                           L_highest=High_M1[j];
                           L_highest_pos=j;
                        }
                    }
                    ObjectCreate(0,"wave3",OBJ_TEXT,0,Time_M1[L_highest_pos],L_highest+50*d_point);
                    ObjectSetString(0,"wave3",OBJPROP_TEXT,"[3]");
                 }
              }
           }
        }
     }
     //波浪标记4
     if((ObjectFind(0,"wave3")>=0)&&(ObjectFind(0,"wave4")<0))
     {
        last_wave_price=ObjectGetDouble(0,"wave3",OBJPROP_PRICE,0)-50*d_point;
        wave2_time=ObjectGetInteger(0,"wave2",OBJPROP_TIME,0);
        if(nowp>last_wave_price)
        {
           ObjectSetInteger(0,"wave3",OBJPROP_TIME,Time_M1[barsnum_M1-1]);
           ObjectSetDouble(0,"wave3",OBJPROP_PRICE,nowp+50*d_point);
        }
        last_wave_time=ObjectGetInteger(0,"wave3",OBJPROP_TIME,0);
        last_wave_price=ObjectGetDouble(0,"wave3",OBJPROP_PRICE,0)-50*d_point;
        for(i=0;i<tlines_D;i++)
        {
            if((Time_M1[LineShow_D[i][1]-10]<last_wave_time)&&(High_M1[LineShow_D[i][1]]>last_wave_price)&&(last_wave_time<Time_M1[barsnum_M1-30]))
            break;
        }
        if(i<tlines_D)dis=LineShow_D[i][0]-LineShow_D[i][1];
        else dis=0;
        if(dis!=0)
        {
           div=High_M1[LineShow_D[i][0]]-High_M1[LineShow_D[i][1]];
           breakP1=div*(barsnum_M1-1-LineShow_D[i][0])/dis+High_M1[LineShow_D[i][0]];
           breakP3=div*(barsnum_M1-3-LineShow_D[i][0])/dis+High_M1[LineShow_D[i][0]];
           breakP4=div*(barsnum_M1-4-LineShow_D[i][0])/dis+High_M1[LineShow_D[i][0]];
           if(nowp>breakP1+50*d_point)
           {
              if(ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]]<ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]])
              {
                 if(Time_M5[ZigZagBuffer_pos_M5[1]]>last_wave_time)
                 {
                    ObjectCreate(0,"wave4",OBJ_TEXT,0,Time_M5[ZigZagBuffer_pos_M5[1]],ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]]);
                    ObjectSetString(0,"wave4",OBJPROP_TEXT,"[4]");
                 }
              }
              else 
              {
                  if(Time_M5[ZigZagBuffer_pos_M5[2]]>last_wave_time)
                  {
                     ObjectCreate(0,"wave4",OBJ_TEXT,0,Time_M5[ZigZagBuffer_pos_M5[2]],ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]]);
                     ObjectSetString(0,"wave4",OBJPROP_TEXT,"[4]");
                  }
              }
           }
           if(High_M1[barsnum_M1-3]>breakP3+5*d_point)
           {
              if((nowp>High_M1[barsnum_M1-2]+5*d_point)&&(High_M1[barsnum_M1-2]>High_M1[barsnum_M1-3])&&(High_M1[barsnum_M1-4]<=breakP4))
              {
                 if(ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]]<ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]])
                 {
                    if(Time_M5[ZigZagBuffer_pos_M5[1]]>last_wave_time)
                    {
                       ObjectCreate(0,"wave4",OBJ_TEXT,0,Time_M5[ZigZagBuffer_pos_M5[1]],ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]]+50*d_point);
                       ObjectSetString(0,"wave4",OBJPROP_TEXT,"[4]");
                    }
                 }
                 else 
                 {
                     if(Time_M5[ZigZagBuffer_pos_M5[2]]>last_wave_time)
                     {
                        ObjectCreate(0,"wave4",OBJ_TEXT,0,Time_M5[ZigZagBuffer_pos_M5[2]],ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]]+50*d_point);
                        ObjectSetString(0,"wave4",OBJPROP_TEXT,"[4]");
                     }
                 }
              }
           }
        }
     }
     //波浪标记5
     if((ObjectFind(0,"wave4")>=0)&&(ObjectFind(0,"wave5")<0))
     {
        last_wave_price=ObjectGetDouble(0,"wave4",OBJPROP_PRICE,0);
        wave1_time=ObjectGetInteger(0,"wave3",OBJPROP_TIME,0);
        if(nowp<last_wave_price)
        {
           ObjectSetInteger(0,"wave4",OBJPROP_TIME,Time_M1[barsnum_M1-1]);
           ObjectSetDouble(0,"wave4",OBJPROP_PRICE,nowp);
        }
        last_wave_time=ObjectGetInteger(0,"wave4",OBJPROP_TIME,0);
        last_wave_price=ObjectGetDouble(0,"wave4",OBJPROP_PRICE,0);
        for(i=0;i<tlines_U;i++)
        {
            if((Time_M1[LineShow_U[i][1]-10]<=last_wave_time)&&(Low_M1[LineShow_U[i][1]]<=last_wave_price)&&(last_wave_time<Time_M1[barsnum_M1-30]))
            break;
        }
        if(i<tlines_U)dis=LineShow_U[i][0]-LineShow_U[i][1];
        else dis=0;
        if(dis!=0)
        {
           div=Low_M1[LineShow_U[i][0]]-Low_M1[LineShow_U[i][1]];
           breakP1=div*(barsnum_M1-1-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
           breakP3=div*(barsnum_M1-3-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
           breakP4=div*(barsnum_M1-4-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
           if(nowp>ObjectGetDouble(0,"wave1",OBJPROP_PRICE,0))
           {
              L_highest=High_M1[LineShow_U[i][1]];
              L_highest_pos=LineShow_U[i][1];
              if(nowp<breakP1-50*d_point)
              {
                 for(j=LineShow_U[i][1];j<=barsnum_M1-1;j++)
                 {
                     if((High_M1[j]>L_highest)&&(Time_M1[j]>wave3_time))
                     {
                        L_highest=High_M1[j];
                        L_highest_pos=j;
                     }
                 }
                 ObjectCreate(0,"wave5",OBJ_TEXT,0,Time_M1[L_highest_pos],L_highest+50*d_point);
                 ObjectSetString(0,"wave5",OBJPROP_TEXT,"[5]");
              }
              if(High_M1[barsnum_M1-3]<breakP3-5*d_point)
              {
                 if((nowp<High_M1[barsnum_M1-2]-5*d_point)&&(High_M1[barsnum_M1-2]<High_M1[barsnum_M1-3])&&(High_M1[barsnum_M1-4]>=breakP4))
                 {
                    for(j=LineShow_U[i][1];j<=barsnum_M1-1;j++)
                    {
                        if((High_M1[j]>L_highest)&&(Time_M1[j]>wave3_time))
                        {
                           L_highest=High_M1[j];
                           L_highest_pos=j;
                        }
                    }
                    ObjectCreate(0,"wave5",OBJ_TEXT,0,Time_M1[L_highest_pos],L_highest+50*d_point);
                    ObjectSetString(0,"wave5",OBJPROP_TEXT,"[5]");
                 }
              }
           }
        }
     }
     
     //波浪更新 5之后更新
     double wave4_price=ObjectGetDouble(0,"wave4",OBJPROP_PRICE,0);
     if((ObjectFind(0,"wave5")>=0)&&(ObjectFind(0,"wave0_big")<0))
     {
        last_wave_price=ObjectGetDouble(0,"wave5",OBJPROP_PRICE,0)-50*d_point;
        if(nowp>last_wave_price)
        {
           ObjectSetInteger(0,"wave5",OBJPROP_TIME,Time_M1[barsnum_M1-1]);
           ObjectSetDouble(0,"wave5",OBJPROP_PRICE,nowp+50*d_point);
        }
        last_wave_time=ObjectGetInteger(0,"wave5",OBJPROP_TIME,0);
        last_wave_price=ObjectGetDouble(0,"wave5",OBJPROP_PRICE,0)-50*d_point;
        for(i=0;i<tlines_D;i++)
        {
            if((Time_M1[LineShow_D[i][1]-10]<=last_wave_time)&&(High_M1[LineShow_D[i][1]]>=last_wave_price))
            break;
        }
        if(i<tlines_D)dis=LineShow_D[i][0]-LineShow_D[i][1];
        else dis=0;
        if(dis!=0)
        {
           div=High_M1[LineShow_D[i][0]]-High_M1[LineShow_D[i][1]];
           breakP1=div*(barsnum_M1-1-LineShow_D[i][0])/dis+High_M1[LineShow_D[i][0]];
           breakP3=div*(barsnum_M1-3-LineShow_D[i][0])/dis+High_M1[LineShow_D[i][0]];
           breakP4=div*(barsnum_M1-4-LineShow_D[i][0])/dis+High_M1[LineShow_D[i][0]];
           if(Low_M1[LineShow_D[i][2]]<wave4_price)
           {
              if(nowp>breakP1+50*d_point)
              {
                 if(ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]]<ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]])
                 {
                    ObjectCreate(0,"wave0_big",OBJ_TEXT,0,0,0);
                    ObjectSetDouble(0,"wave0_big",OBJPROP_PRICE,ObjectGetDouble(0,"wave0",OBJPROP_PRICE,0));
                    ObjectSetInteger(0,"wave0_big",OBJPROP_TIME,ObjectGetInteger(0,"wave0",OBJPROP_TIME,0));
                    ObjectSetString(0,"wave0_big",OBJPROP_TEXT,"(0)");
                    
                    ObjectCreate(0,"wave1_big",OBJ_TEXT,0,0,0);
                    ObjectSetDouble(0,"wave1_big",OBJPROP_PRICE,ObjectGetDouble(0,"wave5",OBJPROP_PRICE,0));
                    ObjectSetInteger(0,"wave1_big",OBJPROP_TIME,ObjectGetInteger(0,"wave5",OBJPROP_TIME,0));
                    ObjectSetString(0,"wave1_big",OBJPROP_TEXT,"(1)");
                    
                    ObjectCreate(0,"wave2_big",OBJ_TEXT,0,Time_M5[ZigZagBuffer_pos_M5[1]],ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]]);
                    ObjectSetString(0,"wave2_big",OBJPROP_TEXT,"(2)");
                    
                    ObjectDelete(0,"wave0");
                    ObjectDelete(0,"wave1");
                    ObjectDelete(0,"wave2");
                    ObjectDelete(0,"wave3");
                    ObjectDelete(0,"wave4");
                    ObjectDelete(0,"wave5");
                 }
                 else 
                 {
                     ObjectCreate(0,"wave0_big",OBJ_TEXT,0,0,0);
                     ObjectSetDouble(0,"wave0_big",OBJPROP_PRICE,ObjectGetDouble(0,"wave0",OBJPROP_PRICE,0));
                     ObjectSetInteger(0,"wave0_big",OBJPROP_TIME,ObjectGetInteger(0,"wave0",OBJPROP_TIME,0));
                     ObjectSetString(0,"wave0_big",OBJPROP_TEXT,"(0)");
                    
                     ObjectCreate(0,"wave1_big",OBJ_TEXT,0,0,0);
                     ObjectSetDouble(0,"wave1_big",OBJPROP_PRICE,ObjectGetDouble(0,"wave5",OBJPROP_PRICE,0));
                     ObjectSetInteger(0,"wave1_big",OBJPROP_TIME,ObjectGetInteger(0,"wave5",OBJPROP_TIME,0));
                     ObjectSetString(0,"wave1_big",OBJPROP_TEXT,"(1)");
                    
                     ObjectCreate(0,"wave2_big",OBJ_TEXT,0,Time_M5[ZigZagBuffer_pos_M5[1]],ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]]+50*d_point);
                     ObjectSetString(0,"wave2_big",OBJPROP_TEXT,"(2)");
                    
                     ObjectDelete(0,"wave0");
                     ObjectDelete(0,"wave1");
                     ObjectDelete(0,"wave2");
                     ObjectDelete(0,"wave3");
                     ObjectDelete(0,"wave4");
                     ObjectDelete(0,"wave5");
                 }
              }
              if(High_M1[barsnum_M1-3]>breakP3+5*d_point)
              {
                 if((nowp>High_M1[barsnum_M1-2]+5*d_point)&&(High_M1[barsnum_M1-2]>High_M1[barsnum_M1-3])&&(High_M1[barsnum_M1-4]<=breakP4))
                 {
                    if(ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]]<ZigZagBuffer_M5[ZigZagBuffer_pos_M5[2]])
                    {
                       ObjectCreate(0,"wave0_big",OBJ_TEXT,0,0,0);
                       ObjectSetDouble(0,"wave0_big",OBJPROP_PRICE,ObjectGetDouble(0,"wave0",OBJPROP_PRICE,0));
                       ObjectSetInteger(0,"wave0_big",OBJPROP_TIME,ObjectGetInteger(0,"wave0",OBJPROP_TIME,0));
                       ObjectSetString(0,"wave0_big",OBJPROP_TEXT,"(0)");
                       
                       ObjectCreate(0,"wave1_big",OBJ_TEXT,0,0,0);
                       ObjectSetDouble(0,"wave1_big",OBJPROP_PRICE,ObjectGetDouble(0,"wave5",OBJPROP_PRICE,0));
                       ObjectSetInteger(0,"wave1_big",OBJPROP_TIME,ObjectGetInteger(0,"wave5",OBJPROP_TIME,0));
                       ObjectSetString(0,"wave1_big",OBJPROP_TEXT,"(1)");
                       
                       ObjectCreate(0,"wave2_big",OBJ_TEXT,0,Time_M5[ZigZagBuffer_pos_M5[1]],ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]]);
                       ObjectSetString(0,"wave2_big",OBJPROP_TEXT,"(2)");
                       
                       ObjectDelete(0,"wave0");
                       ObjectDelete(0,"wave1");
                       ObjectDelete(0,"wave2");
                       ObjectDelete(0,"wave3");
                       ObjectDelete(0,"wave4");
                       ObjectDelete(0,"wave5");
                    }
                    else 
                    {
                        ObjectCreate(0,"wave0_big",OBJ_TEXT,0,0,0);
                        ObjectSetDouble(0,"wave0_big",OBJPROP_PRICE,ObjectGetDouble(0,"wave0",OBJPROP_PRICE,0));
                        ObjectSetInteger(0,"wave0_big",OBJPROP_TIME,ObjectGetInteger(0,"wave0",OBJPROP_TIME,0));
                        ObjectSetString(0,"wave0_big",OBJPROP_TEXT,"(0)");
                       
                        ObjectCreate(0,"wave1_big",OBJ_TEXT,0,0,0);
                        ObjectSetDouble(0,"wave1_big",OBJPROP_PRICE,ObjectGetDouble(0,"wave5",OBJPROP_PRICE,0));
                        ObjectSetInteger(0,"wave1_big",OBJPROP_TIME,ObjectGetInteger(0,"wave5",OBJPROP_TIME,0));
                        ObjectSetString(0,"wave1_big",OBJPROP_TEXT,"(1)");
                       
                        ObjectCreate(0,"wave2_big",OBJ_TEXT,0,Time_M5[ZigZagBuffer_pos_M5[1]],ZigZagBuffer_M5[ZigZagBuffer_pos_M5[1]]+50*d_point);
                        ObjectSetString(0,"wave2_big",OBJPROP_TEXT,"(2)");
                       
                        ObjectDelete(0,"wave0");
                        ObjectDelete(0,"wave1");
                        ObjectDelete(0,"wave2");
                        ObjectDelete(0,"wave3");
                        ObjectDelete(0,"wave4");
                        ObjectDelete(0,"wave5");
                    }
                 }
              }
           }
        }
     }
     //波浪更新 破大通道更新
     if((big_TL>0)&&(ObjectFind(0,"wave0_big")<0))
     {
        i=big_TL-1;
        if(i<tlines_U)dis=LineShow_U[i][0]-LineShow_U[i][1];
        else dis=0;
        if(dis!=0)
        {
           div=Low_M1[LineShow_U[i][0]]-Low_M1[LineShow_U[i][1]];
           breakP1=div*(barsnum_M1-1-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
           breakP3=div*(barsnum_M1-3-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
           breakP4=div*(barsnum_M1-4-LineShow_U[i][0])/dis+Low_M1[LineShow_U[i][0]];
           if(nowp<breakP1-50*d_point)
           {
              if(ObjectFind(0,"wave5")>=0)
              {
                 ObjectCreate(0,"wave0_big",OBJ_TEXT,0,0,0);
                 ObjectSetDouble(0,"wave0_big",OBJPROP_PRICE,ObjectGetDouble(0,"wave0",OBJPROP_PRICE,0));
                 ObjectSetInteger(0,"wave0_big",OBJPROP_TIME,ObjectGetInteger(0,"wave0",OBJPROP_TIME,0));
                 ObjectSetString(0,"wave0_big",OBJPROP_TEXT,"(0)");
                 
                 ObjectCreate(0,"wave1_big",OBJ_TEXT,0,0,0);
                 ObjectSetDouble(0,"wave1_big",OBJPROP_PRICE,ObjectGetDouble(0,"wave5",OBJPROP_PRICE,0));
                 ObjectSetInteger(0,"wave1_big",OBJPROP_TIME,ObjectGetInteger(0,"wave5",OBJPROP_TIME,0));
                 ObjectSetString(0,"wave1_big",OBJPROP_TEXT,"(1)");
                 
                 ObjectDelete(0,"wave0");
                 ObjectDelete(0,"wave1");
                 ObjectDelete(0,"wave2");
                 ObjectDelete(0,"wave3");
                 ObjectDelete(0,"wave4");
                 ObjectDelete(0,"wave5");
              }
              else
              {
                  if(ObjectFind(0,"wave3")>=0)
                  {
                     ObjectCreate(0,"wave0_big",OBJ_TEXT,0,0,0);
                     ObjectSetDouble(0,"wave0_big",OBJPROP_PRICE,ObjectGetDouble(0,"wave0",OBJPROP_PRICE,0));
                     ObjectSetInteger(0,"wave0_big",OBJPROP_TIME,ObjectGetInteger(0,"wave0",OBJPROP_TIME,0));
                     ObjectSetString(0,"wave0_big",OBJPROP_TEXT,"(0)");
                    
                     ObjectCreate(0,"wave1_big",OBJ_TEXT,0,0,0);
                     ObjectSetDouble(0,"wave1_big",OBJPROP_PRICE,ObjectGetDouble(0,"wave3",OBJPROP_PRICE,0));
                     ObjectSetInteger(0,"wave1_big",OBJPROP_TIME,ObjectGetInteger(0,"wave3",OBJPROP_TIME,0));
                     ObjectSetString(0,"wave1_big",OBJPROP_TEXT,"(1)");
                    
                     ObjectDelete(0,"wave0");
                     ObjectDelete(0,"wave1");
                     ObjectDelete(0,"wave2");
                     ObjectDelete(0,"wave3");
                     ObjectDelete(0,"wave4");
                  }
              }
           }
           if(High_M1[barsnum_M1-3]<breakP3-5*d_point)
           {
              if((nowp<High_M1[barsnum_M1-2]-5*d_point)&&(High_M1[barsnum_M1-2]<High_M1[barsnum_M1-3])&&(High_M1[barsnum_M1-4]>=breakP4))
              {
                 if(ObjectFind(0,"wave5")>=0)
                 {
                    ObjectCreate(0,"wave0_big",OBJ_TEXT,0,0,0);
                    ObjectSetDouble(0,"wave0_big",OBJPROP_PRICE,ObjectGetDouble(0,"wave0",OBJPROP_PRICE,0));
                    ObjectSetInteger(0,"wave0_big",OBJPROP_TIME,ObjectGetInteger(0,"wave0",OBJPROP_TIME,0));
                    ObjectSetString(0,"wave0_big",OBJPROP_TEXT,"(0)");
                    
                    ObjectCreate(0,"wave1_big",OBJ_TEXT,0,0,0);
                    ObjectSetDouble(0,"wave1_big",OBJPROP_PRICE,ObjectGetDouble(0,"wave5",OBJPROP_PRICE,0));
                    ObjectSetInteger(0,"wave1_big",OBJPROP_TIME,ObjectGetInteger(0,"wave5",OBJPROP_TIME,0));
                    ObjectSetString(0,"wave1_big",OBJPROP_TEXT,"(1)");
                    
                    ObjectDelete(0,"wave0");
                    ObjectDelete(0,"wave1");
                    ObjectDelete(0,"wave2");
                    ObjectDelete(0,"wave3");
                    ObjectDelete(0,"wave4");
                    ObjectDelete(0,"wave5");
                 }
                 else
                 {
                     if(ObjectFind(0,"wave3")>=0)
                     {
                        ObjectCreate(0,"wave0_big",OBJ_TEXT,0,0,0);
                        ObjectSetDouble(0,"wave0_big",OBJPROP_PRICE,ObjectGetDouble(0,"wave0",OBJPROP_PRICE,0));
                        ObjectSetInteger(0,"wave0_big",OBJPROP_TIME,ObjectGetInteger(0,"wave0",OBJPROP_TIME,0));
                        ObjectSetString(0,"wave0_big",OBJPROP_TEXT,"(0)");
                       
                        ObjectCreate(0,"wave1_big",OBJ_TEXT,0,0,0);
                        ObjectSetDouble(0,"wave1_big",OBJPROP_PRICE,ObjectGetDouble(0,"wave3",OBJPROP_PRICE,0));
                        ObjectSetInteger(0,"wave1_big",OBJPROP_TIME,ObjectGetInteger(0,"wave3",OBJPROP_TIME,0));
                        ObjectSetString(0,"wave1_big",OBJPROP_TEXT,"(1)");
                       
                        ObjectDelete(0,"wave0");
                        ObjectDelete(0,"wave1");
                        ObjectDelete(0,"wave2");
                        ObjectDelete(0,"wave3");
                        ObjectDelete(0,"wave4");
                     }
                 }
              }
           }
        }
     }
     
}

void quickescape()
{
     datetime deal_time=StringToTime(ObjectGetString(0,"deal_time",OBJPROP_TEXT,0));
     if(Time_M5[barsnum_M5-1]>deal_time)
     {
        ObjectsDeleteAll(0,0,OBJ_ARROW_THUMB_UP);
        ObjectsDeleteAll(0,0,OBJ_LABEL);
        fbuy(0,0.01);
        return;
     }
}

void draw_zig(int x)
{
     int i;
     if(x==Bars(_Symbol,PERIOD_H4))
     {
        for(i=1;i<=ZigZagBuffer_num_H4-1;i++)
        {
            ObjectCreate(0,zig+i,OBJ_TREND,0,0,0,0,0);
            ObjectSetInteger(0,zig+i,OBJPROP_COLOR,clrRed);
            ObjectMove(0,zig+i,0,Time_H4[ZigZagBuffer_pos_H4[i]],ZigZagBuffer_H4[ZigZagBuffer_pos_H4[i]]);
            ObjectMove(0,zig+i,1,Time_H4[ZigZagBuffer_pos_H4[i+1]],ZigZagBuffer_H4[ZigZagBuffer_pos_H4[i+1]]);
        }
     }
     if(x==Bars(_Symbol,PERIOD_H1))
     {
        for(i=1;i<=ZigZagBuffer_num_H1-1;i++)
        {
            ObjectCreate(0,zig+i,OBJ_TREND,0,0,0,0,0);
            ObjectSetInteger(0,zig+i,OBJPROP_COLOR,clrRed);
            ObjectMove(0,zig+i,0,Time_H1[ZigZagBuffer_pos_H1[i]],ZigZagBuffer_H1[ZigZagBuffer_pos_H1[i]]);
            ObjectMove(0,zig+i,1,Time_H1[ZigZagBuffer_pos_H1[i+1]],ZigZagBuffer_H1[ZigZagBuffer_pos_H1[i+1]]);
        }
     }
     if(x==Bars(_Symbol,PERIOD_M30))
     {
        for(i=1;i<=ZigZagBuffer_num_M30-1;i++)
        {
            ObjectCreate(0,zig+i,OBJ_TREND,0,0,0,0,0);
            ObjectSetInteger(0,zig+i,OBJPROP_COLOR,clrRed);
            ObjectMove(0,zig+i,0,Time_M30[ZigZagBuffer_pos_M30[i]],ZigZagBuffer_M30[ZigZagBuffer_pos_M30[i]]);
            ObjectMove(0,zig+i,1,Time_M30[ZigZagBuffer_pos_M30[i+1]],ZigZagBuffer_M30[ZigZagBuffer_pos_M30[i+1]]);
        }
     }
     if(x==Bars(_Symbol,PERIOD_M15))
     {
        for(i=1;i<=ZigZagBuffer_num_M15-1;i++)
        {
            ObjectCreate(0,zig+i,OBJ_TREND,0,0,0,0,0);
            ObjectSetInteger(0,zig+i,OBJPROP_COLOR,clrRed);
            ObjectMove(0,zig+i,0,Time_M15[ZigZagBuffer_pos_M15[i]],ZigZagBuffer_M15[ZigZagBuffer_pos_M15[i]]);
            ObjectMove(0,zig+i,1,Time_M15[ZigZagBuffer_pos_M15[i+1]],ZigZagBuffer_M15[ZigZagBuffer_pos_M15[i+1]]);
        }
     }
     if(x==Bars(_Symbol,PERIOD_M5))
     {
        for(i=1;i<=ZigZagBuffer_num_M5-1;i++)
        {
            ObjectCreate(0,zig+i,OBJ_TREND,0,0,0,0,0);
            ObjectSetInteger(0,zig+i,OBJPROP_COLOR,clrRed);
            ObjectMove(0,zig+i,0,Time_M5[ZigZagBuffer_pos_M5[i]],ZigZagBuffer_M5[ZigZagBuffer_pos_M5[i]]);
            ObjectMove(0,zig+i,1,Time_M5[ZigZagBuffer_pos_M5[i+1]],ZigZagBuffer_M5[ZigZagBuffer_pos_M5[i+1]]);
        }
     }
}


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
    //ArrayResize(HighP,DimMaxPos,1);
    //ArrayResize(LowP,DimMaxPos,1);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
     int flag=1;
     datetime time_now=TimeCurrent();
     string symbol_now=_Symbol;
     long id_now=AccountInfoInteger(ACCOUNT_LOGIN);
     
     long id=1134284; //设置账号ID，7位数
     datetime start_day=D'2018.05.01';//设置开始日期 年.月.日
     datetime end_day=D'2018.11.20';//设置终止日期 年.月.日
     string symbol="USOIL'"; //设置交易品种

     //下面这个是限制日期的
     /*
     if((time_now>end_day)||(time_now<start_day))
     {
        flag=0;
        ObjectsDeleteAll(0,0,OBJ_ARROW_THUMB_UP);
        ObjectsDeleteAll(0,0,OBJ_ARROW_THUMB_DOWN);
        ObjectsDeleteAll(0,0,OBJ_LABEL);
        ObjectsDeleteAll(0,0,OBJ_TREND);
        ObjectsDeleteAll(0,0,OBJ_TEXT);
     }
     */
     //下面这个是限制品种的
     /*
     if(symbol!=symbol_now)
     {
        flag=0;
        ObjectsDeleteAll(0,0,OBJ_ARROW_THUMB_UP);
        ObjectsDeleteAll(0,0,OBJ_ARROW_THUMB_DOWN);
        ObjectsDeleteAll(0,0,OBJ_LABEL);
        ObjectsDeleteAll(0,0,OBJ_TREND);
        ObjectsDeleteAll(0,0,OBJ_TEXT);
     }
     */
     //下面这个是限制账号的
     /*
     if(id!=id_now)
     {
        flag=0;
        ObjectsDeleteAll(0,0,OBJ_ARROW_THUMB_UP);
        ObjectsDeleteAll(0,0,OBJ_ARROW_THUMB_DOWN);
        ObjectsDeleteAll(0,0,OBJ_LABEL);
        ObjectsDeleteAll(0,0,OBJ_TREND);
        ObjectsDeleteAll(0,0,OBJ_TEXT);
     }
     */
     
     copy();
     if(flag==1)
     {
        advance(High_M5,Low_M5,barsnum_M5);
        trend(High_M5,Low_M5,Time_M5,LineHP_M5_1,LineHP_M5_2,LineLP_M5_1,LineLP_M5_2,Hnum_M5,Lnum_M5);
        
        Draw_TL();
        caculate_zig(1000,ZigZagBuffer_num_M1,ZigZagBuffer_M1,High_M1,Low_M1,Time_M1,HighMapBuffer_M1,LowMapBuffer_M1,ZigZagBuffer_pos_M1,barsnum_M1);
        caculate_zig(1000,ZigZagBuffer_num_M5,ZigZagBuffer_M5,High_M5,Low_M5,Time_M5,HighMapBuffer_M5,LowMapBuffer_M5,ZigZagBuffer_pos_M5,barsnum_M5);
        caculate_zig(1000,ZigZagBuffer_num_M15,ZigZagBuffer_M15,High_M15,Low_M15,Time_M15,HighMapBuffer_M15,LowMapBuffer_M15,ZigZagBuffer_pos_M15,barsnum_M15);
        caculate_zig(1000,ZigZagBuffer_num_M30,ZigZagBuffer_M30,High_M30,Low_M30,Time_M30,HighMapBuffer_M30,LowMapBuffer_M30,ZigZagBuffer_pos_M30,barsnum_M30);
        caculate_zig(1000,ZigZagBuffer_num_H1,ZigZagBuffer_H1,High_H1,Low_H1,Time_H1,HighMapBuffer_H1,LowMapBuffer_H1,ZigZagBuffer_pos_H1,barsnum_H1);
        caculate_zig(200,ZigZagBuffer_num_H4,ZigZagBuffer_H4,High_H4,Low_H4,Time_H4,HighMapBuffer_H4,LowMapBuffer_H4,ZigZagBuffer_pos_H4,barsnum_H4);
        
        FRA(6,FRAH_M5,FRAL_M5,High_M5,Low_M5,FRAH_M5_pos,FRAL_M5_pos);
        
        int i;
        string s="zz";
        for(i=1;i<=Hnum_M5;i++)
        {
            ObjectCreate(0,s+i,OBJ_TREND,0,0,0,0,0);
            ObjectSetInteger(0,s+i,OBJPROP_RAY_RIGHT,true);
            ObjectSetInteger(0,s+i,OBJPROP_COLOR,clrGold);
            ObjectMove(0,s+i,0,Time_M5[LineHP_M5_1[i]],High_M5[LineHP_M5_1[i]]);
            ObjectMove(0,s+i,1,Time_M5[LineHP_M5_2[i]],High_M5[LineHP_M5_2[i]]);
        }
        for(i=1;i<=Lnum_M5;i++)
        {
            ObjectCreate(0,s+(i+50),OBJ_TREND,0,0,0,0,0);
            ObjectSetInteger(0,s+(i+50),OBJPROP_RAY_RIGHT,true);
            ObjectSetInteger(0,s+(i+50),OBJPROP_COLOR,clrGreenYellow);
            ObjectMove(0,s+(i+50),0,Time_M5[LineLP_M5_1[i]],Low_M5[LineLP_M5_1[i]]);
            ObjectMove(0,s+(i+50),1,Time_M5[LineLP_M5_2[i]],Low_M5[LineLP_M5_2[i]]);
        }
        int temp=Bars(_Symbol,PERIOD_CURRENT);
        draw_zig(temp);
        
        createtag();
        int Flag_trade=PositionSelect(_Symbol);
        double vol=PositionGetDouble(POSITION_VOLUME);
        findtrend();
        
        datetime nowtime=SymbolInfoInteger(_Symbol,SYMBOL_TIME);//当前时间
        HistorySelect(Time_M1[barsnum_M1-5],nowtime);//上一个单全出了以后，就要初始化一下标签
        int order_num=HistoryOrdersTotal();//选择的历史区间内总交易次数
        int ticket=HistoryOrderGetTicket(order_num-1);//这是上一个单的ticket
        
        if(huangjin==true)d_point=10*d_point;
        
        if(Flag_trade==0)
        { 
           if(order_num>0)
           {
              if(HistoryOrderGetInteger(ticket,ORDER_TYPE)==ORDER_TYPE_SELL)
              {
                  ObjectsDeleteAll(0,0,OBJ_ARROW_THUMB_UP);
                  ObjectsDeleteAll(0,0,OBJ_LABEL);
              }
           }
           else trade();
        }
        else
        {
            escape();
        }
        wave();
     }
  }
//+------------------------------------------------------------------+
//| TradeTransaction function                                        |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Tester function                                                  |
//+------------------------------------------------------------------+
double OnTester()
  {
//---
   double ret=0.0;
//---

//---
   return(ret);
  }
//+------------------------------------------------------------------+
