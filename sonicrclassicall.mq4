//+------------------------------------------------------------------+
//|                                                       SonicR.mq4 |
//|                                Copyright 2023, Hoang Tran Nguyen |
//|                                                  Tinhococban.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Hoang Tran Nguyen"
#property link      "Tinhococban.net"
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
input double Lots          =0.01;
input double MaximumRisk   =0.01;
input double DecreaseFactor=3;
input int    MovingPeriod  =12;
input int    MovingShift   =6;
#define MAGICMA  2303

input double TrailingStop  =50;

int CalculateCurrentOrders(string symbol)
  {
   int buys=0,sells=0;
//---
   for(int i=0;i<OrdersTotal();i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
      if(OrderSymbol()==symbol && OrderMagicNumber()==MAGICMA)
        {
         if(OrderType()==OP_BUY)  buys++;
         if(OrderType()==OP_SELL) sells++;
        }
     }
//--- return orders volume
   if(buys>0) return(buys);
   else       return(-sells);
  }
double getEma34High(int ema_period,string symbol)
{

double EMA34=iMA(symbol, 0,ema_period,0,MODE_EMA,PRICE_HIGH,0);
return EMA34;

}
double getEma34Low(int ema_period,string symbol)
{

double EMA34=iMA(symbol, 0,ema_period,0,MODE_EMA,PRICE_LOW,0);
return EMA34;
}

double getEma34(int ema_period,string symbol)
{

double EMA34=iMA(symbol, 0,ema_period,0,MODE_EMA,PRICE_CLOSE,0);
return EMA34;
}

double getSMA50(int ema_period,string symbol)
{

double EMA50=iMA(symbol, 0,ema_period,0,MODE_SMA,PRICE_CLOSE,0);
return EMA50;
}

double getEma89(int ema_period,string symbol)
{

double EMA89=iMA(symbol,0,ema_period,0,MODE_EMA,PRICE_CLOSE,0);
return EMA89;
}
double GetStopLoss(int type)
{
double stoploss;
int i;
   if(type)
     {
     i=0;
     while (Low[i]>Low[i+1]) i++;;
     //while (High[i]<High[i+1]) i++;i--;
     //while (Low[i]>Low[i+1]) i++;
      stoploss= Low[i]-3*Point;
      
     }
    else
      {
       i=0;
       while (High[i]<High[i+1]) i++;//i--;
       //while (Low[i]>Low[i+1]) i++;i--;
       //while (High[i]<High[i+1]) i++;
       stoploss= High[i]+3*Point;
      } 
      return stoploss;
}

int OnInit()
  {
//---
   
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
//| Calculate optimal lot size                                       |
//+------------------------------------------------------------------+
double LotsOptimized()
  {
   double lot=Lots;
   int    orders=HistoryTotal();     // history orders total
   int    losses=0;                  // number of losses orders without a break
//--- select lot size
   lot=NormalizeDouble(AccountFreeMargin()*MaximumRisk/1000.0,1);
//--- calcuulate number of losses orders without a break
   if(DecreaseFactor>0)
     {
      for(int i=orders-1;i>=0;i--)
        {
         if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==false)
           {
            Print("Error in history!");
            break;
           }
         if(OrderSymbol()!=Symbol() || OrderType()>OP_SELL)
            continue;
         //---
         if(OrderProfit()>0) break;
         if(OrderProfit()<0) losses++;
        }
      if(losses>1)
         lot=NormalizeDouble(lot-lot*losses/DecreaseFactor,1);
     }
//--- return lot size
   if(lot<0.02)lot=0.02;
   return(lot);
  }
//+------------------------------------------------------------------+
//| Check for open order conditions                                  |
//+------------------------------------------------------------------+
void CheckForOpen(int periodtime,string symbol)
  { 
   
 double ema89=getEma89(89,symbol );
 double ema34low=getEma34Low(34,symbol);
 double ema34high=getEma34High(34,symbol);
 double ema34=getEma34(34,symbol);

 int    res;
//--- go trading only for first tiks of new bar
   if(Volume[0]>1) return;
//--- get Moving Average 
   //ma=iMA(NULL,0,MovingPeriod,MovingShift,MODE_SMA,PRICE_CLOSE,0);
//--- sell conditions
   if((ema34low<ema89&&(Open[1]>ema34low && Close[1]<ema34low)&&Close[2]>ema34)||
     (ema34low>ema89&&(Open[1]>ema89 && Close[1]<ema89&&Close[2]>ema89))
      //(Close[1]<Open[1] &&Open[1]<ema34low&&Low[1]>ema34low)
      //(ema34>Open[1]&&Close[1]>ema34high&&ema34<Close[1])
     
   )
     {
        if((Open[1]>ema34high&&Close[1]<ema34low&&ema89<ema34high)//||
           //(Open[1]>ema89&&Close[1]<ema34low && ema34high<ema89)
        )
          //{
          // return;
         // }
        //double x =GetStopLoss(0);
     // if(GetStopLoss(0)-Bid<=500*Point)
        //{
       //res=OrderSend(Symbol(),OP_SELLSTOP,LotsOptimized(),Bid-3*Point,3,GetStopLoss(0),0,"",MAGICMA,0,Red);
       res=OrderSend(Symbol(),OP_SELLSTOP,LotsOptimized(),Low[1]-5*Point,3,GetStopLoss(0),0,"",MAGICMA,0,Red);
        //}
      
      return;
     }
//--- buy conditions
   if((ema34high>ema89&&(Open[1]<ema34high && Close[1]>ema34high)&&Close[2]<ema34high)||
      (ema34high<ema89&&(Open[1]<ema89 && Close[1]>ema89)&&Close[2]<ema89)
      //(Open[1]<Close[1]&&Low[1]<ema34high&&Open[1]>ema34high)
      //(Open[1]>ema34high&&Close[1]>ema34&&ema34high>Close[1])
    
     )
     {
     //if((Open[1]<ema34low&&Close[1]>ema34high&&ema89<=ema34high)||
        //(Open[1]<ema34 && Close[1]>ema89 &&ema89>ema34high)||
       // CheckPartern()
       //)
       //{
        //return;
      // }
     //if(Ask-GetStopLoss(1)<=500*Point)
     double x=  GetStopLoss(1);
     //res=OrderSend(Symbol(),OP_BUYSTOP,LotsOptimized(),Ask+3*Point,3,GetStopLoss(1),0,"",MAGICMA,0,Blue);
     res=OrderSend(Symbol(),OP_BUYSTOP,LotsOptimized(),High[1]+5*Point,3,GetStopLoss(1),0,"",MAGICMA,0,Blue);      
     return;
     }
//---
  }  
  
  void CloseforNews()
  { 
      for(int i=0;i<OrdersTotal();i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
      if(OrderMagicNumber()!=MAGICMA || OrderSymbol()!=Symbol()) continue;
      //--- check order type 
   
        if(OrderType()==OP_BUY)
        {

            if(!OrderClose(OrderTicket(),OrderLots(),Bid,3,White))
               Print("OrderClose error ",GetLastError());
               break;
        }
        if(OrderType()==OP_SELL)
        {

            if(!OrderClose(OrderTicket(),OrderLots(),Ask,3,White))
               Print("OrderClose error ",GetLastError());
               break;
        }   
         
      }
  
  }
  
 void Check_TrainningStop()
 {
  if(OrderType()==OP_BUY)
    {
     
    }
  else
    {
     
    } 
 } 
  
//+------------------------------------------------------------------+
//| Check for close order conditions                                 |
//+------------------------------------------------------------------+
void CheckForClose(int periodtime, string symbol)
  {

//--- go trading only for first tiks of new bar
 if(Volume[0]>1) return;

//--- get Moving Average 
  // ma=iMA(NULL,0,MovingPeriod,MovingShift,MODE_SMA,PRICE_CLOSE,0);
   //string Symbol()=Symbol()
 double ema89=getEma89(89,symbol);
 double ema34low=getEma34Low(34,symbol);
 double ema34high=getEma34High(34,symbol);
 double ema34=getEma34(34,symbol);
 double sma50=getSMA50(50,symbol);
 double Spread = MarketInfo(Symbol(), MODE_SPREAD);
 double PriceAsk = MarketInfo(Symbol(), MODE_ASK);
 double PriceBid = MarketInfo(Symbol(), MODE_BID); 

//---
   for(int i=0;i<OrdersTotal();i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
      if(OrderMagicNumber()!=MAGICMA || OrderSymbol()!=symbol) continue;
      //--- check order type 
      if(OrderType()==OP_BUY)
        {
         if(Low[1]>ema34low&&ema34low>ema89)
           {
            return;
           }
         if((Close[1]<ema34low&&ema89>ema34low)||
            (Close[1]<ema89&& ema89<ema34low) ||Close[1]<sma50
         )
           {
            if(!OrderClose(OrderTicket(),OrderLots(),Bid,3,White))
               Print("OrderClose error ",GetLastError());
               break;
          }
                 
            if(TrailingStop>0)
              {
               if(Bid-OrderOpenPrice()>Point*TrailingStop)
                 {
                  if(OrderStopLoss()<Bid-Point*TrailingStop)
                    {
                     //--- modify order and exit
                     double x= GetStopLoss(1);
                     if(!OrderModify(OrderTicket(),OrderOpenPrice(),Bid+Point*TrailingStop,OrderTakeProfit(),0,Green))
                        Print("OrderModify error ",GetLastError());                       
                     return;
                    }
                 }
              } 
         break;
        }
      if(OrderType()==OP_SELL)
        {        
        if(High[1]<ema34high&ema34high<ema89)
          {
           break;
          } 
        if((Close[1]>ema34high&&ema89<ema34high)||
            (Close[1]>ema89&&ema34high<ema89)||sma50>Close[1] )
           {
            if(!OrderClose(OrderTicket(),OrderLots(),Ask,3,White))
              Print("OrderClose error ",GetLastError());
              break;
           }
                     //--- check for trailing stop
            if(TrailingStop>0 )
              {
               if((OrderOpenPrice()-Ask)>(Point*TrailingStop))
                 {
                  if((OrderStopLoss()>(Ask+Point*TrailingStop)) || (OrderStopLoss()==0))
                    {
                     //--- modify order and exit
                     if(!OrderModify(OrderTicket(),OrderOpenPrice(),Ask+TrailingStop*Point,OrderTakeProfit(),0,Red))
                        Print("OrderModify error ",GetLastError());                          
                     return;
                    }
                 }
              }
         break;
        }        
 
     }
     
  }  
  
//---
  
//+------------------------------------------------------------------+
//| OnTick function                                                  |
//+-------
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+

void OnTick()
  {
  
  if(CalculateCurrentOrders(Symbol())!=0)
    {
     tStop(Symbol(),TrailingStop,Symbol()+"PERIOD_M15");
    }
//---
   //--- check for history and trading
   if(Bars<100 || IsTradeAllowed()==false)
      return;
      

   if(CalculateCurrentOrders(Symbol())==0)//&&CheckTimeTrading()
   {
    CheckForOpen(PERIOD_M15,Symbol());
    }
   else 
   {
   CheckForClose(PERIOD_M15,Symbol());
   XoaLenhCu(Symbol());
   }
  }



void tStop(string symb,int stop, string comment)// Symbol + stop in pips + magic number
  {
   double bsl=NormalizeDouble(MarketInfo(symb,MODE_BID)-stop*MarketInfo(symb,MODE_POINT),MarketInfo(symb,MODE_DIGITS));
   double ssl=NormalizeDouble(MarketInfo(symb,MODE_ASK)+stop*MarketInfo(symb,MODE_POINT),MarketInfo(symb,MODE_DIGITS));

   for(int i=OrdersTotal()-1; i>=0; i--)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
         if(OrderComment()==comment)
            if(OrderSymbol()==symb)

               if(OrderType()==OP_BUY && (OrderStopLoss()<bsl || OrderStopLoss()==0))
                  if(OrderModify(OrderTicket(),OrderOpenPrice(),bsl,OrderTakeProfit(),0,clrNONE))
                    {
                     Print(symb+" Buy's Stop Trailled to "+(string)bsl);
                       }else{
                     Print(symb+" Buy's Stop Trail ERROR");
                    }

               if(OrderType()==OP_SELL && (OrderStopLoss()>ssl || OrderStopLoss()==0))
                  if(OrderModify(OrderTicket(),OrderOpenPrice(),ssl,OrderTakeProfit(),0,clrNONE))
                    {
                     Print(symb+" Sell's Stop Trailled to "+(string)ssl);
                       }else{
                     Print(symb+" Sell's Stop Trail ERROR");
                    }
     }
  }
  
  
  bool CheckSells(string symbol)
  {
    bool result =false;
    double ema89=getEma89(89,symbol );
    double ema34low=getEma34Low(34,symbol);
    double ema34high=getEma34High(34,symbol);
    double ema34=getEma34(34,symbol);
 
  return result;
  }
  
    void XoaLenhCu(string comment)
  {
   for(int i=OrdersTotal()-1;i>=0;i--)
     {
      if(!OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) continue;
      if(OrderComment()==comment)
        {
        OrderDelete(OrderTicket(),Red);
         
        } 
      
     }
  }