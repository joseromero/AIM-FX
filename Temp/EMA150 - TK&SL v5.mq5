//+------------------------------------------------------------------+
//|                                                       EMA150.mq5 |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#include <Expert\Expert.mqh>
#include <Trade\Trade.mqh>

//+------------------------------------------------------------------+
//| Constantes                                                       |
//+------------------------------------------------------------------+

// Constantes para definición de la posición a tomar
static int POSICION_COMPRA = 1;
static int POSICION_VENTA = 2;
static int SIN_POSICION = 0;

// Constantes para definición de estado de los Flags
static bool FLAG_PRENDIDO = true;
static bool FLAG_APAGADO = false;

//Constantes para tipo de Cruce EMA
static int CRUZA_ARRIBA = 1;
static int CRUZA_ABAJO = 2;
static int NO_CRUZA = -1;

//Valor si no ha entrado al mercado
static int SIN_ENTRADA = -1;

//+------------------------------------------------------------------+
//| Parametros Externos - Optimizables                               |
//+------------------------------------------------------------------+

// Cantidad de días para el calculo de EMA diario y EMA por hora
input int totalDias_EMA = 150;
input int totalHoras_EMA = 150;

// Parametros MACD (fast EMA, slow EMA y signal EMA)
input int fast_MACD = 12;
input int slow_MACD = 26;
input int signal_MACD = 9;

// Cantidad de días a esperar para Rebote
input int diasSenalRebote = 5;

// Cantidad de horas a esperar tras señal Rebote
input int horasSenalEjecucion = 48;

//Stop Loss
input double stopLossATR = 1;

//Take Profit
input double takeProfitProporcion = 2;

// Tamaño de buffer (ventana) de MACD diario
input int bufferMACD = 4;

// StopLoss 2
input double stopLossProporcion2 = 0.5;

//Inclinación minima esperada para recalcular la posición
input double inclinacion = 0.07;

// Proximidad de EMA en ATRs
input double proximidadEMA = 0.01;

// Separación del precio con respecto a EMA en ATRs para generar alerta de señal
input double separacionEMA = 1;

// Margen (%) aceptación MACD para cierre de entrada
input double margenAceptacionMACD = 0.01;

//Riesgo a utilizar en entradas
input double riesgoEntradas = 0.005;

//+------------------------------------------------------------------+
//| Variables Globales
//+------------------------------------------------------------------+

// Variable para validar si tick referencia una nueva vela en su respectivo tiempo
bool nuevaVelaDia = false;
bool nuevaVelaHora = false;

//Tiempo de la ultima vela ejecutada
static datetime tiempoUltimaVelaDia;
static datetime tiempoUltimaVelaHora;

//Ejecutor posiciones
CTrade trade;

//Tipo de posición a jugar
int posicion;

//Flag Señal EMA, Señal MACD, Señal Rebote, Señal Orden
bool FSEMA = FLAG_APAGADO;
bool FSMACD = FLAG_APAGADO;
bool FSR = FLAG_APAGADO;
bool FSO = FLAG_APAGADO;
bool FSM = FLAG_APAGADO;
bool FPC = FLAG_APAGADO;

//Handle de Indicadores
int diaEMA_hnd;
int diaMACD_hnd;
int horaMACD_hnd;
int diaATR_hnd;

//Indicadores
double diaEMA[];
double diaMACD[];
double horaMACD[];
double horaSenalMACD[];
double diaATR[];

// Valor de precio de velas
MqlRates velas[];

// Valor de tiempo actual
datetime tiempoActualDia[];
datetime tiempoActualHora[];

//Horas Transcurridos (Horas dependiendo de la etapa actual)
int numPeriodos = 0;

//Identificador de ultima posición abierta
ulong ultimaEntrada = SIN_ENTRADA;


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   diaEMA_hnd = iMA(Symbol(), PERIOD_D1, totalDias_EMA, 0, MODE_EMA, PRICE_CLOSE);
   diaMACD_hnd = iMACD(Symbol(), PERIOD_D1, fast_MACD, slow_MACD, signal_MACD, PRICE_CLOSE);
   horaMACD_hnd = iMACD(Symbol(), PERIOD_H1, fast_MACD, slow_MACD, signal_MACD, PRICE_CLOSE);
   diaATR_hnd = iATR(Symbol(),PERIOD_D1, 14);
   
   if(diaEMA_hnd < 0 || diaMACD_hnd < 0 || horaMACD_hnd < 0 || diaATR_hnd < 0){
      Print("Runtime error = ",GetLastError());
      return(INIT_FAILED);
   }
   
   reiniciarMetodo();
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   reiniciarMetodo();
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---   
   // Validar si ya existe una entrada vigente
   if(FSO == FLAG_PRENDIDO){
      if(PositionsTotal() == 0) reiniciarMetodo();
      else{
         monitorearEntrada();
         
         if(FSM == FLAG_APAGADO && FPC == FLAG_APAGADO) evaluarEntradaInicial();
         else if(FPC == FLAG_PRENDIDO) reiniciarMetodo();
      }
   } else {
      // Validar tick con respecto a la generacion de nueva velas
      validarVelaTick();
      
      // Dirigir la evaluación dependiendo de la etapa actual de la metodología.
      if(nuevaVelaHora){
         if(nuevaVelaDia){
            int cruce = cruzaEMA();
            // Validar que existe un cruce de EMA
            if(cruce != NO_CRUZA){
               // Verificar si es el inicio de metodologia o si es un refuerzo de última posición activa
               if(FSEMA == FLAG_APAGADO){
                  idSenalEMA(cruce);
               } else if(FSMACD == FLAG_APAGADO && cruce == posicion){
                  Alert("Nuevo Cruce EMA que refuerza última posicion");
                  numPeriodos = 0;
               }
            }
            
            //Una vez confirmado EMA, validar señal MACD cuando es necesario
            if(FSEMA == FLAG_PRENDIDO && FSMACD == FLAG_APAGADO){
               idSenalMACD();
               if(FSMACD == FLAG_APAGADO){
                  numPeriodos += 24;
               }
            }
         }
         
         //Una vez confirmado EMA, validar etapa de metodlogía tras validación MACD
         if(FSR == FLAG_PRENDIDO){
            idSenalEjecucion();
            if(FSO == FLAG_APAGADO){
               numPeriodos += 1;
            }
         }else if(FSMACD == FLAG_PRENDIDO){
            idSenalRebote();
            if(FSR == FLAG_APAGADO){
               numPeriodos += 1;
            }
         } 
         
         // Validar si expiraron limites de espera
         if(FSEMA == FLAG_PRENDIDO && FSR == FLAG_APAGADO){
            if(numPeriodos >= diasSenalRebote * 24){
               reiniciarMetodo();
            }
         } else if(FSR == FLAG_PRENDIDO && FSO == FLAG_APAGADO){
            if(numPeriodos >=  (diasSenalRebote * 24) + horasSenalEjecucion){
               reiniciarMetodo();
            }
         }
      }
   }
   
      
  }
//+------------------------------------------------------------------+

//-------------------------------------------------------------------+
// Métodos Auxiliares 
//-------------------------------------------------------------------+

// Método que identifica si se persive una señal de EMA (Para iniciar un posible posición)
// con base en la vela anterior.
// Param: el tipo de cruce de EMA
void idSenalEMA(int cruce)
{         
   // Calcular MACD actual y anterior
   actualizarMACD(PERIOD_D1, 0, 1, bufferMACD);
   
   //Verificar corte de EMA por precio - En caso que si, habilitar siguiente etapa (identificar señal MACD)
   if(cruce == CRUZA_ARRIBA){    
      if(diaMACD[ArrayMinimum(diaMACD)] <= 0){
         posicion = POSICION_COMPRA;
         FSEMA = FLAG_PRENDIDO;
         Alert("Cruza EMA Hacia Arriba y MACD <= 0");
      }
   } else if(cruce == CRUZA_ABAJO){
      if(diaMACD[ArrayMaximum(diaMACD)] >= 0){
         posicion = POSICION_VENTA;
         FSEMA = FLAG_PRENDIDO;
         Alert("Cruza Hacia Abajo y MACD >= 0");
      }
   }    
}

// Método que identifica si se persive una señal de MACD (Para iniciar una posible posición)
// con base en la vela anterior. Este metodo se invoca una vez se ha identificado la señal EMA 150.
void idSenalMACD()
{      
   // Calcular MACD actual y anterior
   actualizarMACD(PERIOD_D1, 0, 1, bufferMACD);
   
   // Verificar que MACD atraviesa 0 acorde a la posición establecida - En caso que si, habilitar siguiente etapa (identificar señal Rebote)
   // Si no ha caducado el tiempo de espera, continuar esperando (aumentar numero de periodos en 1)
   int indiceMaximo = ArrayMaximum(diaMACD);
   int indiceMinimo = ArrayMinimum(diaMACD);
   
   if(posicion == POSICION_COMPRA){
      if(diaMACD[indiceMaximo] >= 0){
         if(indiceMaximo < indiceMinimo){
            Alert("Encontro MACD - ", "Numero Periodos: ", numPeriodos, " MACD: ", diaMACD[indiceMaximo], " Tamaño Buffer: ", ArraySize(diaMACD), " Indice MACD: ", indiceMaximo);
            FSMACD = FLAG_PRENDIDO;
         } else {
            reiniciarMetodo();
         }
      }
   } else{
      if(diaMACD[ArrayMinimum(diaMACD)] <= 0){
         if(indiceMinimo < indiceMaximo){
            Alert("Encontro MACD - ", "Numero Periodos: ", numPeriodos, " MACD: ", diaMACD[indiceMinimo], " Tamaño Buffer: ", ArraySize(diaMACD), " Indice MACD: ", indiceMinimo);
            FSMACD = FLAG_PRENDIDO;
         } else {
            reiniciarMetodo();
         }
      }
   }
}


// Método que identifica si se persive una señal de Rebote (Para iniciar una posible posición)
// con base en la vela anterior. Este metodo se invoca una vez se ha identificado la señal MACD.
void idSenalRebote()
{      
   //Calcular valor de velas actual y anterior    
   ArrayFree(velas);
   CopyRates(Symbol(), PERIOD_H1, 0, 2, velas);
   ArraySetAsSeries(velas, true);
   
   // Calcular MACD actual y anterior
   actualizarMACD(PERIOD_H1, 0, 0, 2);
   
   // Verificar que MACD atraviesa 0 acorde a la posición establecida (Rebote) - En caso que si, habilitar siguiente etapa (identificar señal Ejecución)
   // Si no ha caducado el tiempo de espera, continuar esperando (aumentar numero de periodos en 1 y validar precio rebote)
   if(posicion == POSICION_COMPRA){
      if(horaMACD[1] <= 0){
         Alert("Encontro Rebote - ", "Numero Periodos: ", numPeriodos, " MACD: ", horaMACD[1]);
         FSR = FLAG_PRENDIDO;         
      }
   } else{
      if(horaMACD[1] >= 0){
         Alert("Encontro Rebote - ", "Numero Periodos: ", numPeriodos, " MACD: ", horaMACD[1]);
         FSR = FLAG_PRENDIDO;     
      }
   }
}


// Método que identifica si se persive una señal de Ejecución y en caso que si, llevarla al cabo,
// con base en la vela anterior. Este metodo se invoca una vez se ha identificado la señal Rebote.
void idSenalEjecucion()
{    
   // Calcular MACD actual y anterior
   actualizarMACD(PERIOD_H1, 0, 0, 2);
   
   // Verificar que MACD atraviesa 0 acorde a la posición establecida - En caso que si, ejecutar posición
   // Si no ha caducado el tiempo de espera, continuar esperando (aumentar numero de periodos en 1)
   if(posicion == POSICION_COMPRA){
      if(horaMACD[1] >= 0){
         //Ejecutar Compra
         ejecutarOrden();
         FSO = FLAG_PRENDIDO;
      }
   } else{
      if(horaMACD[1] <= 0){
         //Ejecutar Venta
         ejecutarOrden();
         FSO = FLAG_PRENDIDO;
      }
   }
}

//Reinicia Metodo EMA 150
void reiniciarMetodo(){
   
   Alert("Reiniciar, ", "Numero Periodos: ", numPeriodos);
   
   //Restablecer las variables del método
   numPeriodos = 0;
   posicion = SIN_POSICION;
   
   FSEMA = FLAG_APAGADO;
   FSMACD = FLAG_APAGADO;
   FSR = FLAG_APAGADO;
   FSO = FLAG_APAGADO;
   FSM = FLAG_APAGADO;
   FPC = FLAG_APAGADO;
   
   ultimaEntrada = SIN_ENTRADA;
}

// Ejecuta la orden dependiendo del estado de la estrategia y posición identificada
void ejecutarOrden(){

   //Calcular el ATR y EMA
   actualizarATR(0, 2);
   actualizarEMA(0, 2);
   
   //Calcular valor de velas actual y anterior   
   ArrayFree(velas);
   CopyRates(Symbol(), PERIOD_H1, 0, 2, velas);
   ArraySetAsSeries(velas, true);
   
   //Calcular Valores de la Posición
   datetime vidaOrden = TimeTradeServer() + PeriodSeconds(PERIOD_D1);
   double point = SymbolInfoDouble(Symbol(), SYMBOL_POINT);
   double precioEntrada = 0;
   
   if(posicion == POSICION_COMPRA){      
      //Asigna Precio de entrada
      precioEntrada = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
      
      //Valida si el precio actual es adecuado para ejecutar orden (con respecto a EMA)
      if(precioEntrada >= diaEMA[0] - (proximidadEMA * diaATR[0])){ 
         
         // Alerta la fuerza de la señal y la entrada ejecutada (con sus características)
         if(precioEntrada >= diaEMA[0] + (separacionEMA * diaATR[0])) Alert("Tipo Señal: Señal Debil");
         else Alert("Tipo Señal: Señal Fuerte");
         Alert("ATR: " + diaATR[0] + " SL: " + (SymbolInfoDouble(_Symbol,SYMBOL_ASK) - (stopLossATR * diaATR[0])) + " Precio: " + SymbolInfoDouble(_Symbol,SYMBOL_ASK) + " TP: " + (SymbolInfoDouble(_Symbol,SYMBOL_ASK) + (stopLossATR * takeProfitProporcion * diaATR[0])));
         Alert("Volumen: " + calcularLotesEntrada(stopLossATR * diaATR[0]));
         
         //Ejecuta Entrada y guarda el ticket respectivo
         trade.Buy(
            calcularLotesEntrada(stopLossATR * diaATR[0]),             //Volumen
            Symbol(),        //Símbolo
            precioEntrada,  //Precio
            precioEntrada - (stopLossATR * diaATR[0]),        //Stop Loss
            precioEntrada + (stopLossATR * takeProfitProporcion * diaATR[0]),      //Take Profit   
            "Orden Compra (Buy) EMA 150"      // Comentario    
         );
         ultimaEntrada = PositionGetTicket(0);
      }
   } else {
      //Asigna Precio de entrada
      precioEntrada = SymbolInfoDouble(_Symbol,SYMBOL_BID);
      
      //Valida si el precio actual es adecuado para ejecutar orden (con respecto a EMA)
      if(precioEntrada <= diaEMA[0] + (proximidadEMA * diaATR[0])){
         
         // Alerta la fuerza de la señal y la entrada ejecutada (con sus características)
         if(precioEntrada <= diaEMA[0] - (separacionEMA * diaATR[0])) Alert("Tipo Señal: Señal Debil");
         else Alert("Tipo Señal: Señal Fuerte");
         Alert("ATR: " + diaATR[0] + " SL: " + (SymbolInfoDouble(_Symbol,SYMBOL_ASK) - (stopLossATR * diaATR[0])) + " Precio: " + SymbolInfoDouble(_Symbol,SYMBOL_ASK) + " TP: " + (SymbolInfoDouble(_Symbol,SYMBOL_ASK) + (stopLossATR * takeProfitProporcion * diaATR[0])));
         Alert("Volumen: " + calcularLotesEntrada(stopLossATR * diaATR[0]));
         
         //Ejecuta Entrada y guarda el ticket respectivo
         trade.Sell(
            calcularLotesEntrada(stopLossATR * diaATR[0]),             //Volumen
            Symbol(),        //Símbolo
            precioEntrada,  //Precio
            precioEntrada  + (stopLossATR * diaATR[0]),        //Stop Loss
            precioEntrada  - (stopLossATR * takeProfitProporcion * diaATR[0]),      //Take Profit   
            "Orden Venta (Sell) EMA 150"      // Comentario    
         );
         ultimaEntrada = PositionGetTicket(0);
      }
   }
   
   // Guardar ticket de ultima entrada
   Alert("Posiciones : ",PositionsTotal());
   Alert("Ticket Entrada: ", ultimaEntrada);
}


// Metodo que identifica si en la ultima vela hay un cruze (y que tipo es)
// Se apalanca en constantes que describe un cruce
int cruzaEMA(){
   // Calcular valor de vela actual y anterior    
   ArrayFree(velas);
   CopyRates(Symbol(), PERIOD_D1, 1, 2, velas); 
   ArraySetAsSeries(velas, true);  
   
   // Calcular EMA 150 días actual y anterior
   actualizarEMA(1, 2);
   
   int cruza = NO_CRUZA;
   
   //Verificar corte de EMA por precio - En caso que si, habilitar siguiente etapa (identificar señal MACD)
   if(MathMin(velas[0].open, velas[1].close) < diaEMA[0]){    
      if(velas[0].close >= diaEMA[0]){
         cruza = CRUZA_ARRIBA;
      }
   } else if(MathMax(velas[0].open, velas[1].close) > diaEMA[0]){
      if(velas[0].close <= diaEMA[0]){
         cruza = CRUZA_ABAJO;
      }
   }
   
   return cruza;
}

// Con base en el tick actual valida si es una vela diaria (pos 0) y horaria (pos 1) nueva
// Actualiza valores de tiempo ultima vela y tiempo actual
void validarVelaTick() {
   
   // Validar que el tick actual pertenece a una nueva vela
   nuevaVelaDia = false;
   nuevaVelaHora = false;
   
   // Asignar Tiempos de Tick Actual
   ArrayFree(tiempoActualDia);
   CopyTime(_Symbol, PERIOD_D1, 0, 1, tiempoActualDia);
   
   ArrayFree(tiempoActualHora);
   CopyTime(_Symbol, PERIOD_H1, 0, 1, tiempoActualHora);
   
   // Validar si es una nueva vela diaria
   if(tiempoUltimaVelaDia != tiempoActualDia[0]){
      nuevaVelaDia = true;
      tiempoUltimaVelaDia = tiempoActualDia[0];
   }
   
   // Validar si es una nueva vela horaria
   if(tiempoUltimaVelaHora != tiempoActualHora[0]){
      nuevaVelaHora = true;
      tiempoUltimaVelaHora = tiempoActualHora[0];
   }
}

// Metodo que monitorea la posición una vez se abrio
void monitorearEntrada() {

   // Calcular MACD actual y 2 velas anterior
   actualizarMACD(PERIOD_D1, 0, 0, 2);
   
   if(posicion == POSICION_COMPRA){
      if(diaMACD[0] < diaMACD[1]*(1 - margenAceptacionMACD)){
         //Cerrar Posición
         trade.PositionClose(ultimaEntrada);
         FPC = FLAG_PRENDIDO;
         Alert("Cerrar Posición por regla MACD");
      }
   } else {
      if(diaMACD[0] > diaMACD[1]*(1 + margenAceptacionMACD)){
         //Cerrar Posición
         trade.PositionClose(ultimaEntrada);
         FPC = FLAG_PRENDIDO;
         Alert("Cerrar Posición por regla MACD");
      }
   }  
}

void evaluarEntradaInicial(){

   // Solicitar datos de la ultima posición
   PositionSelectByTicket(ultimaEntrada);
   double takeProfitPosicion = PositionGetDouble(POSITION_TP);
   double openPricePosicion = PositionGetDouble(POSITION_PRICE_OPEN);
   
   // Calcular precios para evaluar posición (inicialmente se asume que es compra).
   double precioEvaluacionPosicion = openPricePosicion + 0.95*(takeProfitPosicion - openPricePosicion);
   double precioTick = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double point = SymbolInfoDouble(Symbol(), SYMBOL_POINT);
   
   if(posicion == POSICION_VENTA){
      precioEvaluacionPosicion = openPricePosicion - (0.95*(openPricePosicion - takeProfitPosicion));
      precioTick = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   }
   
   if(posicion == POSICION_COMPRA && precioEvaluacionPosicion <= precioTick){
      // Calcular MACD actual y 2 velas anterior
      actualizarMACD(PERIOD_D1, 0, 0, 2);
      
      if((diaMACD[0] - diaMACD[1])/diaMACD[1] >= inclinacion){
         //Calcular el ATR
         actualizarATR(0, 2);
      
         //Modificar Posición
         trade.PositionModify(ultimaEntrada, precioTick - (stopLossATR * stopLossProporcion2 * diaATR[0]), precioTick + (10000 * point));
         FSM = FLAG_PRENDIDO;
         Alert("Modificar (Reforzar) Posición por regla MACD");
      }
               
   } else if(posicion == POSICION_VENTA && precioEvaluacionPosicion >= precioTick){
      // Calcular MACD actual y 2 velas anterior
      actualizarMACD(PERIOD_D1, 0, 0, 2);
      
      if((diaMACD[0] - diaMACD[1])/diaMACD[1] >= inclinacion){
         //Calcular el ATR
         actualizarATR(0, 2);
         
         //Modificar Posición
         trade.PositionModify(ultimaEntrada, precioTick + (stopLossATR * stopLossProporcion2 * diaATR[0]), precioTick - (10000 * point));
         FSM = FLAG_PRENDIDO;
         Alert("Modificar (Reforzar) Posición por regla MACD");
      }
   }
}

//Actualiza el valor del indicador EMA 
void actualizarEMA(int inicio, int periodos){
   ArrayFree(diaEMA);
   CopyBuffer(diaEMA_hnd, 0, inicio, periodos, diaEMA);
   ArraySetAsSeries(diaEMA, true);
}

//Actualiza el valor del indicador MACD
void actualizarMACD(ENUM_TIMEFRAMES timeFrame, int nivel, int inicio, int periodos){
   if(timeFrame == PERIOD_D1){
      ArrayFree(diaMACD);
      CopyBuffer(diaMACD_hnd, nivel, inicio, periodos, diaMACD);
      ArraySetAsSeries(diaMACD, true);
   } else if(timeFrame == PERIOD_H1){
      ArrayFree(horaMACD);
      CopyBuffer(horaMACD_hnd, nivel, inicio, periodos, horaMACD);
      ArraySetAsSeries(horaMACD, true);
   }
}

//Actualiza el valor del indicador ATR
void actualizarATR(int inicio, int periodos){
   ArrayFree(diaATR);
   CopyBuffer(diaATR_hnd, 0, inicio, periodos, diaATR);
   ArraySetAsSeries(diaATR, true);
}

// Calcula los lotes con base en nivel de riesgo
double calcularLotesEntrada(double stopLoss, int posicion)
{ 
   double balanceActual = AccountInfoDouble(ACCOUNT_BALANCE);
   string account_currency = AccountInfoString(ACCOUNT_CURRENCY);
   string quoted_currency = SymbolInfoString(_Symbol, SYMBOL_CURRENCY_PROFIT);
   int leverage = AccountInfoInteger(ACCOUNT_LEVERAGE);
   
   double risk = riesgoEntradas * balanceActual;
   
   double lotPrice = 100000 * SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   if(posicion == POSICION_VENTA) lotPrice = 100000 * SymbolInfoDouble(_Symbol, SYMBOL_BID);
   
   double posicionMaxima = (balanceActual * leverage) / lotPrice;   
   
   if(account_currency != quoted_currency) {
      Alert("Account_currency: " + account_currency + " " "Quoted_currency: " + quoted_currency);
      MqlTick tick; 
         if(SymbolSelect(account_currency + quoted_currency, true)) {
            Alert("Encontro: " + account_currency + quoted_currency);
            SymbolInfoTick(account_currency + quoted_currency, tick);
            
            int conversion = tick.ask;
            if(posicion == POSICION_VENTA) conversion = conversion * tick.bid;
            
            risk = risk * conversion;
            posicionMaxima = (balanceActual * leverage * conversion) / lotPrice;
            Alert("Convertion Rate: " + conversion + " " + "Risk: " + risk);
         } else {
            Alert("Encontro: " + quoted_currency + account_currency);
            SymbolInfoTick(quoted_currency + account_currency, tick);
            
            int conversion = tick.ask;
            if(posicion == POSICION_VENTA) conversion = conversion * tick.bid;
            
            risk = risk / conversion;
            posicionMaxima = (balanceActual * leverage / conversion) / lotPrice;
         } 
   }
   
   double lotes = risk /(stopLoss * 100000);
   if(lotes > posicionMaxima) lotes = posicionMaxima;
   lotes = NormalizeDouble(lotes , 2);  
   return lotes;
}