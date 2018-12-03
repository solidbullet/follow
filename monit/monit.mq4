//+------------------------------------------------------------------+
//|                                                        monit.mq4 |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- create timer
   EventSetTimer(3);
      
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- destroy timer
   EventKillTimer();
      
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
      string resp;
      string orders;
      string hisOrders;
      //Print("Account profit ", AccountProfit());
      string equity = DoubleToStr(AccountEquity(),2);
      string balance = DoubleToStr(AccountBalance(),2);
      string profits = DoubleToStr(AccountProfit(),2);
      //double profits;
      int total = OrdersTotal();
      for(int i =0;i<total;i++)
      {
         string order;
         if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
         {
            string ticket = IntegerToString(OrderTicket());
            string time = TimeToStr(OrderOpenTime()+60*60*6);
            string type = IntegerToString(OrderType());
            double lots = DoubleToStr(OrderLots());
            string symbol = OrderSymbol();
            string price = DoubleToStr(OrderOpenPrice(),MarketInfo(Symbol(),MODE_DIGITS));
            string sl = DoubleToStr(OrderStopLoss(),MarketInfo(Symbol(),MODE_DIGITS));
            string tp = DoubleToStr(OrderTakeProfit(),MarketInfo(Symbol(),MODE_DIGITS));
            string profit = DoubleToStr(OrderProfit()+OrderCommission()+OrderSwap(),2);
            string magic = IntegerToString(OrderMagicNumber());
            order=StringConcatenate(ticket,",",time,",",type,",",lots,",",symbol,",",price,",",sl,",",tp,",",profit,",",magic); 
         }
         StringAdd(orders,order);
         StringAdd(orders,";");
      }

      
      int histotal = OrdersHistoryTotal();
      for(int i =histotal-1;i>=0;i--)
      {
         string order;
         if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY))
         {
            if(TimeCurrent() -OrderCloseTime() > 60*60*12) break; 
            string ticket = IntegerToString(OrderTicket());
            string time = TimeToStr(OrderCloseTime()+60*60*6);
            string type = IntegerToString(OrderType());
            double lots = DoubleToStr(OrderLots());
            string symbol = OrderSymbol();
            string price = DoubleToStr(OrderOpenPrice(),MarketInfo(Symbol(),MODE_DIGITS));
            string sl = DoubleToStr(OrderStopLoss(),MarketInfo(Symbol(),MODE_DIGITS));
            string tp = DoubleToStr(OrderTakeProfit(),MarketInfo(Symbol(),MODE_DIGITS));
            string profit = DoubleToStr(OrderProfit()+OrderCommission()+OrderSwap(),2);
            string magic = IntegerToString(OrderMagicNumber());
            order=StringConcatenate(ticket,",",time,",",type,",",lots,",",symbol,",",price,",",sl,",",tp,",",profit,",",magic); 
         }
         StringAdd(hisOrders,order);
         StringAdd(hisOrders,";");

      }
      
      
      resp = StringConcatenate(profits,"@",orders,"@",hisOrders,"@",equity,"@",balance,"@",AccountInfoInteger(ACCOUNT_LOGIN));
      Print(hisOrders);
      
      send(resp,"http://www.hiiboy.com/monit");
  }
//+------------------------------------------------------------------+

string send(string data,string url)
{
   string cookie=NULL,headers; 
   char   post[],result[]; 
   ResetLastError(); 
   //string str="name=jyq&age=30";
   //string str1="usdjpy:0.4,xauusd:0.4,usdcad:0.2";
   StringToCharArray(data,post);
   string str;
   int res=WebRequest("POST",url,NULL,500,post,result,headers); 
   if(res==-1) 
     { 
      Print("Error in WebRequest. Error code  =",GetLastError()); 
      //MessageBox("Add the address '"+url+"' to the list of allowed URLs on tab 'Expert Advisors'","Error",MB_ICONINFORMATION); 
     } 
   else 
     { 
      if(res==200) 
        { 
            str = CharArrayToString(result,0,-1,CP_ACP);
        } 
      else 
         PrintFormat("Downloading '%s' failed, error code %d",url,res); 
     } 
     return str;
}
