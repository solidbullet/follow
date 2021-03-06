#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"

input double      scale=1;//跟单放大系数
string url = "http://hiiboy.com/mt5";
int OnInit()
  {
   return(INIT_SUCCEEDED);
  }
void OnDeinit(const int reason)
  {

  }
void OnTick()
  {
  
  }
  
void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result)
  {
   string post;
   ulong    ticket; 
   ulong hticket; 
   double   lots; 
   string   symbol;
   int   entry; 
   int   type; 
   int  magic;
   double     sl; 
   double     tp; 
   long     positionID; 
   if(result.order >0)
   {
      hticket = result.deal;
      ticket = result.order;
      if(HistoryDealSelect(hticket))
      {
         symbol = HistoryDealGetString(hticket,DEAL_SYMBOL);
         lots =HistoryDealGetDouble(hticket,DEAL_VOLUME);
         entry = HistoryDealGetInteger(hticket,DEAL_ENTRY);
         type = HistoryDealGetInteger(hticket,DEAL_TYPE); 
         //Print(HistoryDealGetInteger(hticket,DEAL_ORDER)); 
      }

      if(HistoryOrderSelect(ticket))
      {
         //symbol=  HistoryOrderGetString(ticket,ORDER_SYMBOL); ORDER_MAGIC
         //entry=   HistoryOrderGetInteger(ticket,ORDER_TIME_SETUP); 
         //type=    HistoryOrderGetInteger(ticket,ORDER_TIME_DONE); 
         //lots=    HistoryOrderGetDouble(ticket,ORDER_VOLUME_INITIAL);//ORDER_VOLUME_CURRENT
         sl=      HistoryOrderGetDouble(ticket,ORDER_SL); 
         tp=      HistoryOrderGetDouble(ticket,ORDER_TP);
         magic =      HistoryOrderGetInteger(ticket,ORDER_MAGIC); 
         positionID =      HistoryOrderGetInteger(ticket,ORDER_POSITION_ID); 
         //Print(symbol," , ",entry," , ",type," , ",lots," , ",sl," , ",tp);  
      }
      StringAdd(post,IntegerToString(ticket));
      StringAdd(post,",");
      StringAdd(post,symbol);
      StringAdd(post,","); 
      StringAdd(post,IntegerToString(entry));
      StringAdd(post,",");
      StringAdd(post,IntegerToString(type));
      StringAdd(post,",");
      StringAdd(post,DoubleToString(formatlots(symbol,lots*scale),2));
      StringAdd(post,",");
      StringAdd(post,DoubleToString(sl,5));
      StringAdd(post,",");
      StringAdd(post,DoubleToString(tp,5));
      StringAdd(post,",");
      StringAdd(post,IntegerToString(magic));
      StringAdd(post,",");
      StringAdd(post,"0");
      StringAdd(post,",");
      StringAdd(post,IntegerToString(positionID));
      Print(post);
      if(entry == DEAL_ENTRY_IN || entry == DEAL_ENTRY_OUT) send(post);//XAUUSD,0,0,0.02,1.1234,2.2345,88,0,pos_id

   } 
   
  }


string send(string data)
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
     return str;
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