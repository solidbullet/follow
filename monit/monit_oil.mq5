//+------------------------------------------------------------------+
//|                                                        monit.mq4 |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include <Trade\PositionInfo.mqh>
#include <Trade\HistoryOrderInfo.mqh>

CPositionInfo positioninfo;
CHistoryOrderInfo h_position;
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
      string equity = DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY),2);
      string balance = DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE),2);
      string profits = DoubleToString(AccountInfoDouble(ACCOUNT_PROFIT),2);
      //double profits;
      int total = PositionsTotal();
      ulong ticket,deal_ticket;
      string type,symbol,price,sl,tp,profit,magic,lots,time;
      string hticket,htype,hsymbol,hprice,hsl,htp,hprofit,hmagic,hlots,htime;
      for(int i =0;i<total;i++)
      {
         string order;
         if(positioninfo.SelectByIndex(i))
         //if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
         {
            
            symbol = positioninfo.Symbol();//OrderSymbol();
            int digit = SymbolInfoInteger(symbol,SYMBOL_DIGITS);
            ticket = IntegerToString(positioninfo.Ticket());
            time = TimeToString(positioninfo.Time()+60*60*6);//TimeToStr(OrderOpenTime()+60*60*6);
            type = IntegerToString(positioninfo.Type());//IntegerToString(OrderType());
            lots = DoubleToString(positioninfo.Volume(),2);//DoubleToStr(OrderLots());
            
            price = DoubleToString(positioninfo.PriceOpen(),digit);//DoubleToStr(OrderOpenPrice(),MarketInfo(Symbol(),MODE_DIGITS));
            sl = DoubleToString(positioninfo.StopLoss(),digit);//DoubleToStr(OrderStopLoss(),MarketInfo(Symbol(),MODE_DIGITS));
            tp = DoubleToString(positioninfo.TakeProfit(),digit);//DoubleToStr(OrderTakeProfit(),MarketInfo(Symbol(),MODE_DIGITS));
            profit = DoubleToString(positioninfo.Profit()+positioninfo.Commission()+positioninfo.Swap(),digit);//DoubleToStr(OrderProfit()+OrderCommission()+OrderSwap(),2);
            magic = IntegerToString(positioninfo.Magic());//IntegerToString(OrderMagicNumber());
            
            StringConcatenate(order,ticket,",",time,",",type,",",lots,",",symbol,",",price,",",sl,",",tp,",",profit,",",magic); 
            
         }
         StringAdd(orders,order);
         StringAdd(orders,";");  
      }

      HistorySelect(TimeCurrent()-60*60*12,TimeCurrent()); 
      int histotal = HistoryOrdersTotal();
      for(int i =histotal-1;i>=0;i--)
      {
         string horder;
         if((ticket=HistoryOrderGetTicket(i))>0)
         {
            deal_ticket= HistoryDealGetTicket(i);
            //Print("deal: ",deal_ticket," order: ",ticket);
            if(HistoryDealGetInteger(deal_ticket,DEAL_ENTRY) == DEAL_ENTRY_IN) continue;
            hticket = IntegerToString(HistoryOrderGetInteger(ticket,ORDER_TICKET));
            
            htime=  TimeToString((datetime)(HistoryOrderGetInteger(ticket,ORDER_TIME_SETUP)+60*60*6)); 
            hsymbol = HistoryOrderGetString(ticket,ORDER_SYMBOL);
            int digit = SymbolInfoInteger(hsymbol,SYMBOL_DIGITS);
            htype=  (int)!HistoryOrderGetInteger(ticket,ORDER_TYPE);
            hlots = DoubleToString(HistoryOrderGetDouble(ticket,ORDER_VOLUME_INITIAL),2);
            hprice=  HistoryOrderGetDouble(ticket,ORDER_PRICE_CURRENT); 
            hsl = DoubleToString(HistoryOrderGetDouble(ticket,ORDER_SL),digit);
            htp = DoubleToString(HistoryOrderGetDouble(ticket,ORDER_TP),digit);
            hprofit = DoubleToString(HistoryDealGetDouble(deal_ticket,DEAL_PROFIT)+HistoryDealGetDouble(deal_ticket,DEAL_SWAP)+HistoryDealGetDouble(deal_ticket,DEAL_COMMISSION),2);
            hmagic=  HistoryOrderGetInteger(ticket,ORDER_MAGIC);
            
            StringConcatenate(horder,hticket,",",htime,",",htype,",",hlots,",",hsymbol,",",hprice,",",hsl,",",htp,",",hprofit,",",hmagic); 
           
         }
         
         StringAdd(hisOrders,horder);
         StringAdd(hisOrders,";");
         
      }

      //Print(hisOrders);
      
      StringConcatenate(resp,profits,"@",orders,"@",hisOrders,"@",equity,"@",balance,"@",AccountInfoInteger(ACCOUNT_LOGIN));
      //StringConcatenate(resp,profits,"@",hisOrders,"@",equity,"@",balance,"@",AccountInfoInteger(ACCOUNT_LOGIN));
      //StringConcatenate(resp,profits,"@",orders,"@",hisOrders,"@",equity,"@",balance,"@","1004423");
      //Print(resp);
      
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
