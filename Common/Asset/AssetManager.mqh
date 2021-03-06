//+------------------------------------------------------------------+
//|                                                 AssetManager.mqh |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"

#include <AIM-FX\Common\Global\GlobalInd.mqh>
#include <AIM-FX\Common\Global\GlobalVar.mqh>
#include <AIM-FX\Common\Utilities\ExpertSignal.mqh>
#include <AIM-FX\Signal\EMA150Signal.mqh>
#include <AIM-FX\Trailing\EMA150Trailing.mqh>

class AssetManager{

   private:
   
   //Symbol assigned to the asset manager
   string symbol;
   
   // Valor de tiempo actual
   datetime lastDayTime;
   datetime lastHourTime;
   
   //--------------------------------------------------------------+
   // Support Objects
   //--------------------------------------------------------------+
   
   // Global Indicator Engine for current Symbol
   GlobalInd* GI; 
   
   //--------------------------------------------------------------+
   // Trading Methods
   //--------------------------------------------------------------+
   
   //EMA 150 Signal
   EMA150Signal* signalEMA150;
   
   //--------------------------------------------------------------+
   // Trailing Methods
   //--------------------------------------------------------------+
   
   //EMA 150 Signal
   EMA150Trailing* trailingEMA150;
   
   //--------------------------------------------------------------+
   //Support Methods
   //--------------------------------------------------------------+
   
   //Checks current tick, valdates if it is a new hour / day candlestick 
   void validateTick();
   
   
   public:
   
   //--------------------------------------------------------------+
   //Constructor
   //--------------------------------------------------------------+
   
   //Constructor for Asset Manager assigned to specified symbol
   AssetManager(string p_simbolo); 

};

//--------------------------------------------------------------+
//Constructor
//--------------------------------------------------------------+

//Constructor for Asset Manager assigned to specified symbol
AssetManager::AssetManager(string p_symbol){
   symbol = p_symbol;
   GI = new GlobalInd(symbol);
   signalEMA150 = new EMA150Signal(150, 150, 12, 26, 9, 5, 48, 1, 2, 0.5, 4, 0.07, 0.01, 1, 0.01, 0.005, GI, symbol);
}


//--------------------------------------------------------------+
//Support Methods
//--------------------------------------------------------------+

//Checks current tick, valdates if it is a new hour / day candlestick
void AssetManager::validateTick() {
   
   // Create variables to get current time for each timeframe   
   datetime dayTime[1];
   datetime hourTime[1];
   
   int newCandleStick = GlobalVar::SAME_CANDLESTICK;
   
   // Asignar Tiempos de Tick Actual
   GI.getTimeTick(PERIOD_D1, dayTime);
   GI.getTimeTick(PERIOD_H1, hourTime);
   
   // Validar si es una nueva vela diaria
   if(lastDayTime != dayTime[0]){
      lastDayTime = dayTime[0];
      newCandleStick = GlobalVar::DAY_CANDLESTICK;
   } 
   
   if(lastHourTime != hourTime[0]) {
      lastHourTime = hourTime[0];
      if(newCandleStick == GlobalVar::SAME_CANDLESTICK) newCandleStick = GlobalVar::HOUR_CANDLESTICK;
   }
}


