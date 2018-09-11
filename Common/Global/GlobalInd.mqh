//+------------------------------------------------------------------+
//|                                                    GlobalInd.mqh |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#include <Generic\HashMap.mqh>

class GlobalInd{

   private:
   
      //Tabla Hash para mapear indicadores generados
      CHashMap<string, int>* indicadores;
      
      //Simbolo activo asociado
      string simbolo;
   
   public:

      //Constructor Controlador Global de Indicadores
      GlobalInd(string p_Simbolo);
      
      //Crear un nuevo indicador EMA
      void crearEMA(ENUM_TIMEFRAMES periodo, int cantidad_periodos);
      
      //Crear un nuevo indicador MACD
      void crearMACD(ENUM_TIMEFRAMES periodo, int fast_MACD, int slow_MACD, int signal_MACD);
      
      //Crear un nuevo indicador ATR
      void crearATR(ENUM_TIMEFRAMES periodo, int cantidad_periodos);
      
      //Dar valores de velas
      void darVelas(ENUM_TIMEFRAMES periodo,int inicio, MqlRates& valores[]);
      
      //Dar valores de indicador EMA
      void darEMA(ENUM_TIMEFRAMES periodo, int cantidad_periodos, int inicio, double& valores[]);
      
      //Dar valores de indicador MACD
      void darMACD(ENUM_TIMEFRAMES periodo, int fast_MACD, int slow_MACD, int signal_MACD, int inicio, double& valores[]);
      
      //Dar valores de indicador ATR
      void darATR(ENUM_TIMEFRAMES periodo, int cantidad_periodos, int inicio, double& valores[]);
      
      //Dar Valor actual de Ask
      double darAsk();
      
      //Dar Valor actual de Bid
      double darBid();
      
      //Returns the point value of current Asset.
      double getPoint();
      
      //Updates dates param with current tick time considering specified time frames
      void getTimeTick(ENUM_TIMEFRAMES timeFrame, datetime& dates[]);
      
      
};

//Constructor Controlador Global de Indicadores
GlobalInd::GlobalInd(string p_Simbolo){ 
   simbolo = p_Simbolo;
   indicadores = new CHashMap<string, int>();
}

//Crear un nuevo indicador EMA
//Param: Parametros de Indicador EMA
void GlobalInd::crearEMA(ENUM_TIMEFRAMES periodo, int cantidad_periodos){
   
   string llave = simbolo + " - EMA" + cantidad_periodos + " - " + periodo;
   if(!indicadores.ContainsKey(llave)){
      int EMA_hnd = iMA(simbolo, periodo, cantidad_periodos, 0, MODE_EMA, PRICE_CLOSE);
      if(EMA_hnd < 0) Print("Runtime error = ",GetLastError()); 
      indicadores.Add(llave, EMA_hnd);
   }
}

//Crear un nuevo indicador MACD
//Param: Parametros de Indicador MACD
void GlobalInd::crearMACD(ENUM_TIMEFRAMES periodo, int fast_MACD, int slow_MACD, int signal_MACD){
   
   string llave = simbolo + " - MACD - F" + fast_MACD + "S" + slow_MACD + "SG" + signal_MACD + " - " + periodo;
   if(!indicadores.ContainsKey(llave)){
      int MACD_hnd = iMACD(simbolo, periodo, fast_MACD, slow_MACD, signal_MACD, PRICE_CLOSE);
      if(MACD_hnd < 0) Print("Runtime error = ",GetLastError());
      indicadores.Add(llave, MACD_hnd);
   }
}

//Crear un nuevo indicador ATR
//Param: Parametros de Indicador ATR
void GlobalInd::crearATR(ENUM_TIMEFRAMES periodo, int cantidad_periodos){
   
   string llave = simbolo + " - ATR" + cantidad_periodos + " - " + periodo;
   if(!indicadores.ContainsKey(llave)){
      int ATR_hnd = iATR(simbolo, periodo, cantidad_periodos);
      if(ATR_hnd < 0) Print("Runtime error = ", GetLastError());
      indicadores.Add(llave, ATR_hnd);
   }
}

//Dar valores de velas
void GlobalInd::darVelas(ENUM_TIMEFRAMES periodo, int inicio, MqlRates& valores[]){

   CopyRates(simbolo, periodo, inicio, ArraySize(valores), valores);
   ArraySetAsSeries(valores, true);
}

//Dar valores de indicador EMA
void GlobalInd::darEMA(ENUM_TIMEFRAMES periodo, int cantidad_periodos, int inicio, double& valores[]){
   
   string llave = simbolo + " - EMA" + cantidad_periodos + " - " + periodo;
   if(!indicadores.ContainsKey(llave)){
      int EMA_hnd = -1;
      indicadores.TryGetValue(llave, EMA_hnd);
      
      CopyBuffer(EMA_hnd, 0, inicio, ArraySize(valores), valores);
      ArraySetAsSeries(valores, true);
   } else ArrayFill(valores, 0, ArraySize(valores), -1);
}

//Dar valores de indicador MACD
void GlobalInd::darMACD(ENUM_TIMEFRAMES periodo, int fast_MACD, int slow_MACD, int signal_MACD, int inicio, double& valores[]){
   
   string llave = simbolo + " - MACD - F" + fast_MACD + "S" + slow_MACD + "SG" + signal_MACD + " - " + periodo;
   if(!indicadores.ContainsKey(llave)){
      int MACD_hnd = -1;
      indicadores.TryGetValue(llave, MACD_hnd);
      
      CopyBuffer(MACD_hnd, 0, inicio, ArraySize(valores), valores);
      ArraySetAsSeries(valores, true);
   } else ArrayFill(valores, 0, ArraySize(valores), -1);
}

//Dar valores de indicador ATR
void GlobalInd::darATR(ENUM_TIMEFRAMES periodo, int cantidad_periodos, int inicio, double& valores[]){
   
   string llave = simbolo + " - ATR" + cantidad_periodos + " - " + periodo;
   if(!indicadores.ContainsKey(llave)){
      int ATR_hnd = -1;
      indicadores.TryGetValue(llave, ATR_hnd);
      
      CopyBuffer(ATR_hnd, 0, inicio, ArraySize(valores), valores);
      ArraySetAsSeries(valores, true);
   } else ArrayFill(valores, 0, ArraySize(valores), -1);
}

//Dar Valor actual de Ask
double GlobalInd::darAsk(){
   return SymbolInfoDouble(simbolo, SYMBOL_ASK);
}

//Dar Valor actual de Bid
double GlobalInd::darBid(){
   return SymbolInfoDouble(simbolo, SYMBOL_BID);
}

//Returns the point value of current Asset.
double GlobalInd::getPoint(){
   return SymbolInfoDouble(simbolo, SYMBOL_POINT);
}

//Updates dates param with current tick time considering specified time frames
void GlobalInd::getTimeTick(ENUM_TIMEFRAMES timeFrame, datetime& dates[]){
   CopyTime(simbolo, timeFrame, 0, ArraySize(dates), dates);
}