#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

int kaiguan = 0;
int button1_kg = 1; //button的开关控制
int button2_kg = 1; //button的开关控制
int button3_kg = 1; //button的开关控制
long chart_id=ChartID(); 
string str[3][2];

string url="http://www.hiiboy.com/mt4"; 

int OnInit()
  {
  /*
   ObjectsDeleteAll(chart_id,0,OBJ_EDIT);
   ObjectsDeleteAll(chart_id,0,OBJ_BUTTON);
   str[0][0] = "50022817";
   str[0][1] = IntegerToString(1);
   str[1][0] = "40017678";
   str[1][1] = IntegerToString(1);
   str[2][0] = "30017678";
   str[2][1] = IntegerToString(1);
   draw_object("edit1",str[0][0],"button1",10,20);
   draw_object("edit2",str[1][0],"button2",10,40);
   draw_object("edit3",str[2][0],"button3",10,60);
   //ventSetTimer(60);
   */
   return(INIT_SUCCEEDED);
  }
  
void OnDeinit(const int reason)
  {

  }
  
void OnTick()
  {
//---
  string data_remote = send("tick");//先去查询服务器端的数据 
  Sleep(250);
  }
  
  

//+------------------------------------------------------------------+
string send(string data)//往服务器发数据
{
   string cookie=NULL,headers; 
   char   post[],result[]; 
   
   ResetLastError(); 
   StringToCharArray(data,post);
   string str = "";
   int res=WebRequest("POST",url,NULL,5000,post,result,headers); 
   if(res==-1) 
     { 
      Print("接收端报错: Error in WebRequest. Error code  =",GetLastError()); 
      MessageBox("Add the address '"+url+"' to the list of allowed URLs on tab 'Expert Advisors'","Error",MB_ICONINFORMATION); 
     } 
   else 
     { 
      if(res==200) 
        { 
            str = CharArrayToString(result,0,WHOLE_ARRAY,CP_ACP);
            //Print(str);
            deal_go(str);
            
        } 
      else 
         PrintFormat("Downloading '%s' failed, error code %d",url,res); 
     } 
     return str;
}

string convert_symbol(string sy)
{
 string sy_new;
 if(sy == "OILUS") sy_new = "OILUSe";
 if(sy == "OILUK") sy_new = "OILUKe";
 else return sy;
 return sy_new;
}

void deal_go(string to_split)
{
   //string status,mt5ticket,sy;
   //int entry,type,magic;
   //double lots,sl,tp;
   if(StringLen(to_split) == 0) return;
   Print(to_split);
   string sep=",";                // 分隔符为字符 
   ushort u_sep;                  // 分隔符字符代码 
   string result[];               // 获得字符串数组 
   u_sep=StringGetCharacter(sep,0); 
   int k=StringSplit(to_split,u_sep,result); 
   string status = result[0];
   string mt5ticket = result[1];
   string sy = convert_symbol(result[2]);
   int entry = StrToInteger(result[3]);//0表示开单，买进或者卖出，1表示平仓单
   int type = StrToInteger(result[4]);//0表示buy单，1表示sell单
   double lots = NormalizeDouble(StrToDouble(result[5]),2);
   double sl = StrToDouble(result[6]);
   double tp = StrToDouble(result[7]);
   int magic = StrToInteger(result[8]);
   double ask    = MarketInfo(sy,MODE_ASK); 
   double bid    = MarketInfo(sy,MODE_BID);
   string accountId = result[11];
   Print("accountID: ",accountId);
//open,mt5ticket,XAUUSD,0,0,0.02,1.1234,2.2345,88,mt4ticket,pos_id,Accountid
// 0  ,    1    ,   2  ,3,4, 5  ,   6  ,  7   ,8 ,     9   ,  10	 ,  11  
   if(status == "open" && is_Auth(accountId)) 
   {

      if(type == 0)
      {
         int res = OrderSend(sy,OP_BUY,lots,ask,150,sl,tp,mt5ticket,magic,0,0);
         if(res>0)
         {
            string s = StringConcatenate("openok,",mt5ticket,",",IntegerToString(res));
            response(s);
            Sleep(150);
         }else{ 
         Print("OrderSend failed with error #",GetLastError()); 
         } 
      
      }
      if(type == 1)
      {
         int res = OrderSend(sy,OP_SELL,lots,bid,150,sl,tp,mt5ticket,magic,0,0);
         if(res>0) 
         {
            string s = StringConcatenate("openok,",mt5ticket,",",IntegerToString(res));
            response(s);
            Sleep(150);
         }else{ 
         Print("OrderSend failed with error #",GetLastError()); 
         }  
      }   
   }
   
//CLOSE_HAND_TICKET,mt5ticketIN,XAUUSD,0,0,0.02,1.1234,2.2345,88,mt4ticket,pos_id,userid,mt5ticketOUT,CloseLots
//         0       ,      1    ,   2  ,3,4, 5  ,   6  ,  7   ,8 ,     9   ,  10	 ,  11  ,      12    ,   13 
   if(status == "CLOSE_HAND_TICKET")
   {
      string mt5out_ticket = result[12];
      int ticket = result[9];
      double close_lots = NormalizeDouble(StringToDouble(result[13]),2); 
      double diff_lots = NormalizeDouble(lots - close_lots,2);
      //close_lots = (diff_lots == 0 || diff_lots == lots/2)?close_lots:lots;//解决放大系数是0.5倍时候有0.01平不掉的问题
      
      Print("lots ",lots,"  close_lots ",close_lots,"  diff_lots  ",diff_lots," equal ",NormalizeDouble(diff_lots,2) == 0.01);
      //diff_lots = formatlots(sy,diff_lots);
      if(NormalizeDouble(diff_lots,2) == 0.01) close_lots=lots;
      if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
      {
         bool res = OrderClose(ticket,close_lots,OrderClosePrice(),150,0);
         
         if(res)
         {
            string s;
            if(diff_lots > 0)
            {
               int pos = OrdersHistoryTotal();
               string mt4ticket;
               if(OrderSelect(pos-1,SELECT_BY_POS,MODE_HISTORY))
               {
                  mt4ticket = get_his_comment(OrderComment());
               }  
               s = StringConcatenate("closehalfok,",mt5ticket,",",mt5out_ticket,",",DoubleToString(diff_lots),",",mt4ticket);
            }else s = StringConcatenate("closeallok,",mt5ticket,",",mt5out_ticket);//("closeallok,EAINkey,eaoutKEY")
            response(s);
            Sleep(150);
         } 
         else Print("OrderSend failed with error #",GetLastError()); 
      }
   }
// CLOSE_EA_TICKET ,mt5ticketIN,XAUUSD,0,0,0.02,1.1234,2.2345,88,mt4ticket,pos_id,userid,mt5ticketOUT,CloseLots
//         0       ,      1    ,   2  ,3,4, 5  ,   6  ,  7   ,8 ,     9   ,  10	 ,  11  ,      12    ,   13 
   if(status == "CLOSE_EA_TICKET")
   {
      string mt5out_ticket = result[12]; 
      int ticket = result[9];
      double close_lots = NormalizeDouble(StringToDouble(result[13]),2); 
      double res_lots = NormalizeDouble(lots - close_lots,2);
      res_lots = formatlots(sy,res_lots);
      if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))//res:"closehalf,EAINkey,eaoutKEY,0.01,mt4ticket"
      {
         bool res = OrderClose(ticket,close_lots,OrderClosePrice(),150,0);
         if(res)
         {
            int pos = OrdersHistoryTotal();
            string mt4ticket;
            if(OrderSelect(pos-1,SELECT_BY_POS,MODE_HISTORY))
            {
               mt4ticket = get_his_comment(OrderComment());
            }  
            string s = StringConcatenate("closehalfok,",mt5ticket,",",mt5out_ticket,",",DoubleToString(res_lots),",",mt4ticket);
            response(s);
            Sleep(150);
         } 
         else Print("OrderSend failed with error #",GetLastError()); 
      }
   }

}

void response(string data)//往服务器发数据
{
   string cookie=NULL,headers; 
   char   post[],result[]; 
   ResetLastError(); 
   StringToCharArray(data,post);
   string str = "";
   int res=WebRequest("POST",url,NULL,500,post,result,headers); 
   if(res==-1) 
     { 
      Print("Error in WebRequest. Error code  =",GetLastError()); 
      MessageBox("Add the address '"+url+"' to the list of allowed URLs on tab 'Expert Advisors'","Error",MB_ICONINFORMATION); 
     } 
   else 
     { 
      if(res==200) 
        { 
            str = CharArrayToString(result,0,WHOLE_ARRAY,CP_ACP);
            Print(str);
            
        } 
      else 
         PrintFormat("Downloading '%s' failed, error code %d",url,res); 
     } 
}

string get_his_comment(string to_split)
{
   string sep="#";                // A separator as a character 
   ushort u_sep;                  // The code of the separator character 
   string result[];               // An array to get strings 
   u_sep=StringGetCharacter(sep,0); 
   int k=StringSplit(to_split,u_sep,result);
   return result[k-1];
}

double formatlots(string symbol,double lots)
   {
     double a=0;
     double minilots=SymbolInfoDouble(symbol,SYMBOL_VOLUME_MIN);
     double steplots=SymbolInfoDouble(symbol,SYMBOL_VOLUME_STEP);
     if(lots<minilots) return(0);
     else
      {
        double a1=MathFloor(lots/minilots)*minilots;
        a=a1+MathFloor((lots-a1)/steplots)*steplots;
      }
     return(a);
   }
   
void draw_object(string edit_name,string edit_text,string button_name,int x,int y)
{
   

//--- creating label object (it does not have time/price coordinates) 
   if(!ObjectCreate(chart_id,edit_name,OBJ_EDIT,0,0,0))  Print("Error: can't create label! code #",GetLastError()); 
   if(!ObjectCreate(chart_id,button_name,OBJ_BUTTON,0,0,0))  Print("Error: can't create label! code #",GetLastError()); 
   ObjectSetInteger(chart_id,edit_name,OBJPROP_XDISTANCE,x); 
   ObjectSetInteger(chart_id,edit_name,OBJPROP_YDISTANCE,y); 
   ObjectSetInteger(chart_id,edit_name,OBJPROP_XSIZE,80);
   ObjectSetInteger(chart_id,edit_name,OBJPROP_CORNER,CORNER_LEFT_LOWER);
   ObjectSetInteger(chart_id,button_name,OBJPROP_COLOR,clrMediumBlue);
   ObjectSetText(edit_name,edit_text,10,"Times New Roman",Green);
   
   ObjectSetInteger(chart_id,button_name,OBJPROP_XDISTANCE,x+100); 
   ObjectSetInteger(chart_id,button_name,OBJPROP_YDISTANCE,y); 
   ObjectSetInteger(chart_id,button_name,OBJPROP_CORNER,CORNER_LEFT_LOWER);
   ObjectSetInteger(chart_id,button_name,OBJPROP_BGCOLOR,clrGreenYellow);
   ObjectSetInteger(chart_id,button_name,OBJPROP_COLOR,clrMediumBlue);
   ObjectSetInteger(chart_id,button_name,OBJPROP_XSIZE,80);
   ObjectSetText(button_name,"关闭",8,"Times New Roman",Green);
   
}

void OnChartEvent(const int id,         // Event ID 
                  const long& lparam,   // Parameter of type long event 
                  const double& dparam, // Parameter of type double event 
                  const string& sparam  // Parameter of type string events 
  ){
    
     Turn_Off(sparam,"button1");
     Turn_Off(sparam,"button2");
     Turn_Off(sparam,"button3");
  }
  
  
void Turn_Off(const string& sparam,string buttonName)
{
     if(sparam == buttonName)
     { 
         char suffix = StringGetChar(sparam,6); //button1 返回1，button2返回2  "1" = 49,"2" = 50
         
         switch(suffix) 
           { 
            case 49: 
               button1_kg = -button1_kg;
               kaiguan =  button1_kg;
               break; 
            case 50: 
               button2_kg = -button2_kg; 
               kaiguan =  button2_kg;
               break; 
            case 51: 
               button3_kg = -button3_kg; 
               kaiguan =  button3_kg;
               break; 
           } 
         string editName = "edit";
         StringAdd(editName,suffix-48);
         string eidtText = ObjectGetString(chart_id,editName,OBJPROP_TEXT,0);
         str[suffix-49][0] = eidtText;
         str[suffix-49][1] = IntegerToString(kaiguan);
         if(kaiguan == -1)
         {
            ObjectSetInteger(chart_id,buttonName,OBJPROP_BGCOLOR,clrRed);
            ObjectSetText(buttonName,"等待开启",8,"Times New Roman",Green);
         } 
         else
         {
            ObjectSetText(buttonName,"关闭",8,"Times New Roman",Green);
            ObjectSetInteger(chart_id,buttonName,OBJPROP_BGCOLOR,clrGreenYellow);
         } 
     }
}
bool is_Auth(string account)
{
   bool res = true;
   for(int i = 0;i < 3;i++)
   {
      if(str[i][0] == account && str[i][1] == "-1")
      {
      res = false;
      //Print(i);
      } 
   }
   return res;
}