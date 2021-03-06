//+------------------------------------------------------------------+
//|                                              GlobalUtilities.mqh |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"

class GlobalVar{

   public: 
      // Constantes para definición de la posición a tomar
      static int POSICION_COMPRA;
      static int POSICION_VENTA;
      static int SIN_POSICION;
      
      // Constantes para definición de estado de los Flags
      static bool FLAG_PRENDIDO;
      static bool FLAG_APAGADO;
      
      //Constantes para tipo de Cruce
      static int CRUZA_ARRIBA;
      static int CRUZA_ABAJO;
      static int NO_CRUZA;
      
      //Valor si no ha entrado al mercado
      static int SIN_ENTRADA;
      
      //Static Variables to define possible signal values.
      static int BUY_SIGNAL;
      static int SELL_SIGNAL;
      static int BUYSTOP_SIGNAL;
      static int SELLSTOP_SIGNAL;
      
      //Static Variable to indicate that a signal has no stop value (since it is a BUY or SELL Signal)
      static int NO_STOPVALUE;
      
      //Static Variable to indicate Signal Leven
      static int STRONG_SIGNAL;
      static int WEAK_SIGNAL;
      
      //Static Variables to indicate what type of candlestick began on a tick
      //Note: Order values according to timeframe order
      static int SAME_CANDLESTICK;
      static int HOUR_CANDLESTICK;
      static int DAY_CANDLESTICK;
      
      //Static Varibles to indicate signal messages
      static int NO_MESSAGE;
      static int CLOSE_MESSAGE;
      static int UPDATE_MESSAGE;
      static int CREATE_MESSAGE;
      
      //Static Varible to indicate No ticket id - Used on create messages
      static ulong NO_TICKET_ID;
      
      //Trailing Status - Either Running (with an active entry) or STOPPED (with no active entry)
      static int METHOD_RUNNING;
      static int METHOD_STOPPED;

};

// Inicialización de variables globales
int GlobalVar::POSICION_COMPRA = 1;
int GlobalVar::POSICION_VENTA = 2;
int GlobalVar::SIN_POSICION = 0;
bool GlobalVar::FLAG_PRENDIDO = true;
bool GlobalVar::FLAG_APAGADO = false;
int GlobalVar::CRUZA_ARRIBA = 1;
int GlobalVar::CRUZA_ABAJO = 2;
int GlobalVar::NO_CRUZA = -1;
int GlobalVar::SIN_ENTRADA = -1;

int GlobalVar::BUY_SIGNAL = 1;
int GlobalVar::SELL_SIGNAL = 2;
int GlobalVar::BUYSTOP_SIGNAL = 3;
int GlobalVar::SELLSTOP_SIGNAL = 4;

int GlobalVar::NO_STOPVALUE = -1;

int GlobalVar::STRONG_SIGNAL = 1;
int GlobalVar::WEAK_SIGNAL = 1;

int GlobalVar::SAME_CANDLESTICK = 0;
int GlobalVar::HOUR_CANDLESTICK = 1;
int GlobalVar::DAY_CANDLESTICK = 2;

int GlobalVar::NO_MESSAGE = -1;
int GlobalVar::CLOSE_MESSAGE = 0;
int GlobalVar::CREATE_MESSAGE = 1;
int GlobalVar::UPDATE_MESSAGE = 2;

ulong GlobalVar::NO_TICKET_ID = -1;

int GlobalVar::METHOD_RUNNING = 1;
int GlobalVar::METHOD_STOPPED = 0;





