//+------------------------------------------------------------------+
//|                                               EMA150Trailing.mqh |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"

#include <AIM-FX\Common\Global\GlobalInd.mqh>
#include <AIM-FX\Common\Global\GlobalVar.mqh>
#include <AIM-FX\Common\Utilities\ExpertSignal.mqh>

class EMA150Trailing{
   
   private:
      
      //--------------------------------------------------------------+
      // External Parameteres - Optimization
      //--------------------------------------------------------------+
      
      // MACD Parameters (fast EMA, slow EMA and signal EMA)
      int fast_MACD, slow_MACD, signal_MACD;
      
      //Minimal margin (%) required before stopping the position
      double acceptanceMarginMACD;
      
      //Stop Loss in ATRs for initial position definition
      double stopLossATR;
      
      //Stop Loss (proportion in terms of original one) when a reinforcement event occurs
      double stopLossReinforce;
      
      //Minimal Margin (%) to evaluate if current position should be reinforced
      double reinforeMarginMACD;
      
      
      //--------------------------------------------------------------+
      // Internal Variables
      //--------------------------------------------------------------+
      
      //Asset Symbol
      string symbol;
      
      //Position Ticket
      ulong positionTicket;
      
      //Open price for current Position
      double openPrice;
      
      //Take Profit for current Position
      double takeProfit;
      
      //Stop Loss for current Position
      double stopLoss;
      
      //Position Type - BUY or SELL
      int positionType;
      
      //Internal MACD array for tracking purposes
      double dayMACD[2];
      
      //--------------------------------------------------------------+
      // Flags
      //--------------------------------------------------------------+
            
      //Flag to indicate that current trailing phase is Monitoring Phase
      int FLAG_CLOSE_TRACKING;
      
      //Flag to indicate that current trailing phase is Closing Position Phase
      int FLAG_CLOSE;
      
      //--------------------------------------------------------------+
      // Support Objects
      //--------------------------------------------------------------+
      
      // Global Indicator Engine for current Symbol
      GlobalInd* GI;
      
      //--------------------------------------------------------------+
      // Internal Methods
      //--------------------------------------------------------------+
      
      //Method that evaluates (as first phase) the initial position looking for reinforcement
      void evaluateInitialPosition(ExpertSignal* signal);
      
      //Method that trails till event triggers postion termination
      void positionCloseTracking(ExpertSignal* signal);
      
   
   public:
      
      //--------------------------------------------------------------+
      //Constructor
      //--------------------------------------------------------------+
      
      //Main constructor for EMA150Trailing - Should be used when a position is executed
      EMA150Trailing(int p_fast_MACD,                     
                     int p_slow_MACD,
                     int p_signal_MACD,
                     double p_acceptanceMarginMACD,
                     double p_stopLossATR,
                     double p_stopLossReinforce,
                     double p_reinforeMarginMACD,
                     string p_symbol, 
                     ulong p_positionTicket,
                     double p_openPrice,
                     double p_takeProfit,
                     double p_stopLoss,
                     int p_PositionType, 
                     GlobalInd& p_GI);
      
      //Evaluates the trailing method on tick event. Returns a signal if position should be modified or stopped.              
      ExpertSignal* evaluateTick();
};

//Main constructor for EMA150Trailing - Should be used when a position is executed
EMA150Trailing::EMA150Trailing(int p_fast_MACD, int p_slow_MACD, int p_signal_MACD, double p_acceptanceMarginMACD, double p_stopLossATR, double p_stopLossReinforce,
                     double p_reinforeMarginMACD,string p_symbol, ulong p_positionTicket, double p_openPrice, double p_takeProfit, double p_stopLoss, 
                     int p_positionType, GlobalInd& p_GI){
   fast_MACD = p_fast_MACD;
   slow_MACD = p_slow_MACD;
   signal_MACD = p_signal_MACD;
   acceptanceMarginMACD = p_acceptanceMarginMACD;
   stopLossATR = p_stopLossATR;
   stopLossReinforce = p_stopLossReinforce;
   
   symbol = p_symbol;
   positionTicket = p_positionTicket;
   openPrice= p_openPrice;
   takeProfit = p_takeProfit;
   stopLoss = p_stopLoss;
   positionType = p_positionType;
   GI = p_GI;
   
   FLAG_CLOSE_TRACKING = GlobalVar::FLAG_APAGADO;
   FLAG_CLOSE = GlobalVar::FLAG_APAGADO;
}


//Evaluates the trailing method using the candlestick specified on tick event. Returns a signal if position should be modified or stopped.              
ExpertSignal* EMA150Trailing::evaluateTick(){
      ExpertSignal signal = new ExpertSignal();
      positionCloseTracking(&signal);
      if(FLAG_CLOSE_TRACKING == GlobalVar::FLAG_APAGADO) evaluateInitialPosition(&signal);
      
      return &signal;
}

//Method that evaluates (as first phase) the initial position looking for reinforcement
void EMA150Trailing::evaluateInitialPosition(ExpertSignal* signal){
   
   // Calculates prices required for position evaluation (assuming initially a Buy Position)
   double evaluationPrice = openPrice + 0.95*(takeProfit - openPrice);
   double tickPrice = GI.darBid();
   double point = GI.getPoint();
   double dayATR[2];
   
   if (positionType = GlobalVar::POSICION_VENTA){
      evaluationPrice = openPrice - 0.95*(takeProfit - openPrice);
      tickPrice = GI.darAsk();
   }
   
   if(positionType == GlobalVar::POSICION_COMPRA && evaluationPrice <= tickPrice){
      
      if((dayMACD[0] - dayMACD[1])/dayMACD[1] >= reinforeMarginMACD){
         //Get ATR value for current and last candlestick
         GI.darATR(PERIOD_D1, 14, 0, dayATR);
         
         //Modify Current Posición (Reinforce)
         stopLoss = tickPrice - (stopLossATR * stopLossReinforce * dayATR[0]);
         takeProfit = tickPrice + (10000 * point);
         signal.setUpdateSignal(positionTicket, symbol, takeProfit, stopLoss);
         
         FLAG_CLOSE_TRACKING = GlobalVar::FLAG_PRENDIDO;
         Alert("Modify (Reinforce) current Position - MACD Rule");
      }
   } else if(positionType == GlobalVar::POSICION_VENTA && evaluationPrice >= tickPrice){
      
      if((dayMACD[0] - dayMACD[1])/dayMACD[1] >= reinforeMarginMACD){
         //Get ATR value for current and last candlestick
         GI.darATR(PERIOD_D1, 14, 0, dayATR);
         
         //Modify Current Posición (Reinforce)
         stopLoss = tickPrice + (stopLossATR * stopLossReinforce * dayATR[0]);
         takeProfit = tickPrice - (10000 * point);
         signal.setUpdateSignal(positionTicket, symbol, takeProfit, stopLoss);
         
         FLAG_CLOSE_TRACKING = GlobalVar::FLAG_PRENDIDO;
         Alert("Modify (Reinforce) current Position - MACD Rule");
      }
   }
}

//Method taht trails till event triggers postion termination
void EMA150Trailing::positionCloseTracking(ExpertSignal* signal){
   
   //Get MACD value for current and last candlestick
   ArrayFree(dayMACD);
   GI.darMACD(PERIOD_D1, fast_MACD, slow_MACD, signal_MACD, 0, dayMACD);
   
   if(positionType == GlobalVar::POSICION_COMPRA){
      if(dayMACD[0] < dayMACD[1]*(1 - acceptanceMarginMACD)){
         //Close Current Position
         signal.setCloseSignal(positionTicket, symbol);
         FLAG_CLOSE = GlobalVar::FLAG_PRENDIDO;
         Alert("Position Closed - MACD Rule");
      }
   } else{
      if(dayMACD[0] > dayMACD[1]*(1 + acceptanceMarginMACD)){
         //Close Current Position
         signal.setCloseSignal(positionTicket, symbol);
         FLAG_CLOSE = GlobalVar::FLAG_PRENDIDO;
         Alert("Position Closed - MACD Rule");
      }
   } 
}