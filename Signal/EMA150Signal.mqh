//+------------------------------------------------------------------+
//|                                                       EMA150.mqh |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"

#include <AIM-FX\Common\Global\GlobalInd.mqh>
#include <AIM-FX\Common\Global\GlobalVar.mqh>
#include <AIM-FX\Common\Utilities\ExpertSignal.mqh>

class EMA150Signal{
   
   private:
      
      //--------------------------------------------------------------+
      // Parametros Externos - Optimizables
      //--------------------------------------------------------------+     
      
      // Cantidad de días para el calculo de EMA diario y EMA por hora
      int totalDias_EMA, totalHoras_EMA;
      
      // Parametros MACD (fast EMA, slow EMA y signal EMA)
      int fast_MACD, slow_MACD, signal_MACD;
      
      // Cantidad de días a esperar para Rebote
      int diasSenalRebote;
      
      // Cantidad de horas a esperar tras señal Rebote
      int horasSenalEjecucion;
      
      //Stop Loss
      double stopLossATR;
      
      //Take Profit y Stop Loss 2 en proporción a Stop Loss original (Riesgo Asumido)
      double takeProfitProporcion, stopLossProporcion2;
      
      // Tamaño de buffer (ventana) de MACD diario
      int bufferMACD;
      
      //Inclinación minima esperada para recalcular la posición
      double inclinacion;
      
      // Proximidad de EMA en ATRs
      double proximidadEMA;
      
      // Separación del precio con respecto a EMA en ATRs para generar alerta de señal
      double separacionEMA;
      
      // Margen (%) aceptación MACD para cierre de entrada
      double margenAceptacionMACD;
      
      //Riesgo a utilizar en entradas
      double riesgoEntradas;
      
      //--------------------------------------------------------------+
      // Variables Internas
      //--------------------------------------------------------------+
      
      //Current status of method (Running or Stopped)
      int methodStatus;
      
      //Tipo de posición a jugar
      int posicion;
      
      //Flag Señal EMA, Señal MACD, Señal Rebote, Señal Orden
      bool FSEMA, FSMACD, FSR, FSO;
      
      //Horas Transcurridos (Horas dependiendo de la etapa actual)
      int numPeriodos;
      
      //Identificador de ultima posición abierta
      ulong ultimaEntrada;
      
      //Simbolo en el que esta trabajando
      string simbolo;
      
      
      //--------------------------------------------------------------+
      // Objetos Apoyo
      //--------------------------------------------------------------+
      
      // Global Indicator Engine for current Symbol
      GlobalInd* GI;
      
      
      //--------------------------------------------------------------+
      //Metodos Metodología
      //--------------------------------------------------------------+
      
      //Reinicia Metodo EMA 150
       void reiniciarMetodo();
       
       //Método que identifica si se persive una señal de EMA (Para iniciar un posible posición) con base en la vela anterior.
       void idSenalEMA(int cruce);
       
       // Método que identifica si se persive una señal de MACD (Para iniciar una posible posición) con base en la vela anterior. Este metodo se invoca una vez se ha identificado la señal EMA 150.
       void idSenalMACD();
       
       // Método que identifica si se persive una señal de Rebote (Para iniciar una posible posición) con base en la vela anterior. Este metodo se invoca una vez se ha identificado la señal MACD.
       void idSenalRebote();
       
       // Método que identifica si se persive una señal de Ejecución y en caso que si, llevarla al cabo, con base en la vela anterior. Este metodo se invoca una vez se ha identificado la señal Rebote.
       void idSenalEjecucion(ExpertSignal* signal);
       
       // Metodo que identifica si en la ultima vela hay un cruze (y que tipo es)
       int cruzaEMA();
       
       // Retorna una señal dependiendo del estado de la estrategia y posición identificada 
       void ejecutarSenal(ExpertSignal* signal);
       
   public:
   
      //--------------------------------------------------------------+
      //Constructores
      //--------------------------------------------------------------+
      
      //Constructor de Metodologia EMA 150 - Parametros de entrada son los parametros optimizables
      EMA150Signal(int p_totalDias_EMA,                 
                   int p_totalHoras_EMA,
                   int p_fast_MACD,                     
                   int p_slow_MACD,
                   int p_signal_MACD,
                   int p_diasSenalRebote,
                   int horasSenalEjecucion, 
                   double p_stopLossATR,
                   double p_takeProfitProporcion,
                   double p_stopLossProporcion2,
                   int p_bufferMACD,
                   double p_inclinacion,
                   double p_proximidadEMA,
                   double p_separacionEMA,
                   double p_margenAceptacionMACD,
                   double p_riesgoEntradas,
                   GlobalInd& p_GI,
                   string p_simbolo);
                   
      //--------------------------------------------------------------+
      //Metodo Coordinador Metodología
      //--------------------------------------------------------------+
      
      //Evaluates the methodology using the candlestick specified on tickevent. Returns a signal if method suggest to
      ExpertSignal* evaluateCandleStick(int candleStick);
      
      //--------------------------------------------------------------+
       //Lifecycle Methods
       //--------------------------------------------------------------+
       
       //Start Method - Used when trailing is not executing
       void startMethod();
       
       //Stop Method - Used when trailing is executing
       void stopMethod();
           
};

//--------------------------------------------------------------+
//Constructores
//--------------------------------------------------------------+

//Constructor de la clase EMA150Signal
//Param: Parametros optimizables
EMA150Signal::EMA150Signal(int p_totalDias_EMA, int p_totalHoras_EMA, int p_fast_MACD, int p_slow_MACD, int p_signal_MACD, int p_diasSenalRebote,int p_horasSenalEjecucion,
                   double p_stopLossATR, double p_takeProfitProporcion, double p_stopLossProporcion2, int p_bufferMACD, double p_inclinacion, double p_proximidadEMA,
                   double p_separacionEMA, double p_margenAceptacionMACD, double p_riesgoEntradas, GlobalInd& p_GI, string p_simbolo){
                   
   // Asignación de parametros optimizables   
   totalDias_EMA = p_totalDias_EMA;
   totalHoras_EMA = p_totalHoras_EMA;
   fast_MACD = p_fast_MACD;
   slow_MACD = p_slow_MACD;
   signal_MACD = p_signal_MACD;
   diasSenalRebote = p_diasSenalRebote;
   horasSenalEjecucion = p_horasSenalEjecucion;
   stopLossATR = p_stopLossATR;
   takeProfitProporcion = p_takeProfitProporcion;
   stopLossProporcion2 = p_stopLossProporcion2;
   bufferMACD = p_bufferMACD;
   inclinacion = p_inclinacion;
   proximidadEMA = p_proximidadEMA;
   separacionEMA = p_separacionEMA;
   margenAceptacionMACD = p_margenAceptacionMACD;
   riesgoEntradas = p_riesgoEntradas;
   
   // Inicialización de parametros propios de la metodología
   reiniciarMetodo();
   
   // Asignación de objeto globales e inicializacion de indicadores
   simbolo = p_simbolo;
   GI = p_GI;
   GI.crearEMA(PERIOD_D1, totalDias_EMA);
   GI.crearMACD(PERIOD_D1, fast_MACD, slow_MACD, signal_MACD);
   GI.crearMACD(PERIOD_H1, fast_MACD, slow_MACD, signal_MACD);
   GI.crearATR(PERIOD_D1, 14);
   
   //Start Method - Status Running
   startMethod();
   
}

//--------------------------------------------------------------+
//Lifecycle Methods
//--------------------------------------------------------------+

//Start Method - Used when trailing is not executing
void EMA150Signal::startMethod(){
   methodStatus = GlobalVar::METHOD_RUNNING;
}

//Stop Method - Used when trailing is executing
void EMA150Signal::stopMethod(){
   methodStatus = GlobalVar::METHOD_STOPPED;
}

//--------------------------------------------------------------+
//Metodo Coordinador Metodología
//--------------------------------------------------------------+

//Evaluates the methodology using the candlestick specified on tickevent. Returns a signal if method suggest to
ExpertSignal* EMA150Signal::evaluateCandleStick(int candleStick){
   
   //Create Message Signal - Initially as NO_MESSAGE
   ExpertSignal signal = new ExpertSignal();
   
   // Execute method only when status is running
   if(methodStatus == GlobalVar::METHOD_RUNNING){
      
      // Dirigir la evaluación dependiendo de la etapa actual de la metodología.
      if(candleStick >= GlobalVar::HOUR_CANDLESTICK){
         if(candleStick >= GlobalVar::DAY_CANDLESTICK){
            int cruce = cruzaEMA();
            // Validar que existe un cruce de EMA
            if(cruce != GlobalVar::NO_CRUZA){
               // Verificar si es el inicio de metodologia o si es un refuerzo de última posición activa
               if(FSEMA == GlobalVar::FLAG_APAGADO){
                  idSenalEMA(cruce);
               } else if(FSMACD == GlobalVar::FLAG_APAGADO && cruce == posicion){
                  Alert("Nuevo Cruce EMA que refuerza última posicion");
                  numPeriodos = 0;
               }
            }
            
            //Una vez confirmado EMA, validar señal MACD cuando es necesario
            if(FSEMA == GlobalVar::FLAG_PRENDIDO && FSMACD == GlobalVar::FLAG_APAGADO){
               idSenalMACD();
               if(FSMACD == GlobalVar::FLAG_APAGADO){
                  numPeriodos += 24;
               }
            }
         }
         
         //Una vez confirmado EMA, validar etapa de metodlogía tras validación MACD
         if(FSR == GlobalVar::FLAG_PRENDIDO){
            idSenalEjecucion(&signal);
            if(FSO == GlobalVar::FLAG_APAGADO){
               numPeriodos += 1;
            } else reiniciarMetodo();
         }else if(FSMACD == GlobalVar::FLAG_PRENDIDO){
            idSenalRebote();
            if(FSR == GlobalVar::FLAG_APAGADO){
               numPeriodos += 1;
            }
         } 
         
         // Validar si expiraron limites de espera
         if(FSEMA == GlobalVar::FLAG_PRENDIDO && FSR == GlobalVar::FLAG_APAGADO){
            if(numPeriodos >= diasSenalRebote * 24){
               reiniciarMetodo();
            }
         } else if(FSR == GlobalVar::FLAG_PRENDIDO && FSO == GlobalVar::FLAG_APAGADO){
            if(numPeriodos >=  (diasSenalRebote * 24) + horasSenalEjecucion){
               reiniciarMetodo();
            }
         }
      }
   }
   
   return &signal;
}

//--------------------------------------------------------------+
//Metodos Metodología
//--------------------------------------------------------------+

//Reinicia Metodo EMA 150
void EMA150Signal::reiniciarMetodo(){
   
   Alert("Reiniciar, ", "Numero Periodos: ", numPeriodos);
   
   //Restablecer las variables del método
   numPeriodos = 0;
   posicion = GlobalVar::SIN_POSICION;
   
   FSEMA = GlobalVar::FLAG_APAGADO;
   FSMACD = GlobalVar::FLAG_APAGADO;
   FSR = GlobalVar::FLAG_APAGADO;
   FSO = GlobalVar::FLAG_APAGADO;
   
   ultimaEntrada = GlobalVar::SIN_ENTRADA;
}

//Método que identifica si se persive una señal de EMA (Para iniciar un posible posición) con base en la vela anterior.
//Param: el tipo de cruce de EMA
void EMA150Signal::idSenalEMA(int cruce){         
   
   // Calcular MACD actual y anterior
   double diaMACD[];
   ArrayResize(diaMACD, bufferMACD);
   GI.darMACD(PERIOD_D1, fast_MACD, slow_MACD, signal_MACD, 1, diaMACD);
   
   //Verificar corte de EMA por precio - En caso que si, habilitar siguiente etapa (identificar señal MACD)
   if(cruce == GlobalVar::CRUZA_ARRIBA){    
      if(diaMACD[ArrayMinimum(diaMACD)] <= 0){
         posicion = GlobalVar::POSICION_COMPRA;
         FSEMA = GlobalVar::FLAG_PRENDIDO;
         Alert("Cruza EMA Hacia Arriba y MACD <= 0");
      }
   } else if(cruce == GlobalVar::CRUZA_ABAJO){
      if(diaMACD[ArrayMaximum(diaMACD)] >= 0){
         posicion = GlobalVar::POSICION_VENTA;
         FSEMA = GlobalVar::FLAG_PRENDIDO;
         Alert("Cruza Hacia Abajo y MACD >= 0");
      }
   }
}

// Método que identifica si se persive una señal de MACD (Para iniciar una posible posición) con base en la vela anterior. Este metodo se invoca una vez se ha identificado la señal EMA 150. 
void EMA150Signal::idSenalMACD(){ 
     
   // Calcular MACD actual y anterior
   double diaMACD[];
   ArrayResize(diaMACD, bufferMACD);
   GI.darMACD(PERIOD_D1, fast_MACD, slow_MACD, signal_MACD, 1, diaMACD);
   
   // Verificar que MACD atraviesa 0 acorde a la posición establecida - En caso que si, habilitar siguiente etapa (identificar señal Rebote)
   // Si no ha caducado el tiempo de espera, continuar esperando (aumentar numero de periodos en 1)
   int indiceMaximo = ArrayMaximum(diaMACD);
   int indiceMinimo = ArrayMinimum(diaMACD);
   
   if(posicion == GlobalVar::POSICION_COMPRA){
      if(diaMACD[indiceMaximo] >= 0){
         if(indiceMaximo < indiceMinimo){
            Alert("Encontro MACD - ", "Numero Periodos: ", numPeriodos, " MACD: ", diaMACD[indiceMaximo], " Tamaño Buffer: ", ArraySize(diaMACD), " Indice MACD: ", indiceMaximo);
            FSMACD = GlobalVar::FLAG_PRENDIDO;
         } else {
            reiniciarMetodo();
         }
      }
   } else{
      if(diaMACD[ArrayMinimum(diaMACD)] <= 0){
         if(indiceMinimo < indiceMaximo){
            Alert("Encontro MACD - ", "Numero Periodos: ", numPeriodos, " MACD: ", diaMACD[indiceMinimo], " Tamaño Buffer: ", ArraySize(diaMACD), " Indice MACD: ", indiceMinimo);
            FSMACD = GlobalVar::FLAG_PRENDIDO;
         } else {
            reiniciarMetodo();
         }
      }
   }
}

// Método que identifica si se persive una señal de Rebote (Para iniciar una posible posición) con base en la vela anterior. Este metodo se invoca una vez se ha identificado la señal MACD.
void EMA150Signal::idSenalRebote(){      
   
   //Calcular valor de velas actual y anterior    
   MqlRates velas[2];
   GI.darVelas(PERIOD_H1, 0, velas);
   
   // Calcular MACD actual y anterior
   double horaMACD[2];
   GI.darMACD(PERIOD_H1, fast_MACD, slow_MACD, signal_MACD, 0, horaMACD);
   
   // Verificar que MACD atraviesa 0 acorde a la posición establecida (Rebote) - En caso que si, habilitar siguiente etapa (identificar señal Ejecución)
   // Si no ha caducado el tiempo de espera, continuar esperando (aumentar numero de periodos en 1 y validar precio rebote)
   if(posicion == GlobalVar::POSICION_COMPRA){
      if(horaMACD[1] <= 0){
         Alert("Encontro Rebote - ", "Numero Periodos: ", numPeriodos, " MACD: ", horaMACD[1]);
         FSR = GlobalVar::FLAG_PRENDIDO;         
      }
   } else{
      if(horaMACD[1] >= 0){
         Alert("Encontro Rebote - ", "Numero Periodos: ", numPeriodos, " MACD: ", horaMACD[1]);
         FSR = GlobalVar::FLAG_PRENDIDO;     
      }
   }
}

// Método que identifica si se persive una señal de Ejecución y en caso que si, llevarla al cabo, con base en la vela anterior. Este metodo se invoca una vez se ha identificado la señal Rebote.
void EMA150Signal::idSenalEjecucion(ExpertSignal* signal)
{    
   // Calcular MACD actual y anterior
   double horaMACD[2];
   GI.darMACD(PERIOD_H1, fast_MACD, slow_MACD, signal_MACD, 0, horaMACD);
   
   // Verificar que MACD atraviesa 0 acorde a la posición establecida - En caso que si, ejecutar posición
   // Si no ha caducado el tiempo de espera, continuar esperando (aumentar numero de periodos en 1)
   if(posicion == GlobalVar::POSICION_COMPRA){
      if(horaMACD[1] >= 0){
         //Ejecutar Compra
         ejecutarSenal(signal);
         FSO = GlobalVar::FLAG_PRENDIDO;
      }
   } else{
      if(horaMACD[1] <= 0){
         //Ejecutar Venta
         ejecutarSenal(signal);
         FSO = GlobalVar::FLAG_PRENDIDO;
      }
   }
}

// Metodo que identifica si en la ultima vela hay un cruze (y que tipo es)
int EMA150Signal::cruzaEMA(){
   
   //Calcular valor de velas actual y anterior    
   MqlRates velas[2];
   GI.darVelas(PERIOD_D1, 1, velas);
   
   // Calcular EMA 150 días actual y anterior
   double diaEMA[2];
   GI.darEMA(PERIOD_D1, totalDias_EMA, 1, diaEMA);
   
   int cruza = GlobalVar::NO_CRUZA;
   
   //Verificar corte de EMA por precio - En caso que si, habilitar siguiente etapa (identificar señal MACD)
   if(MathMin(velas[0].open, velas[1].close) < diaEMA[0]){    
      if(velas[0].close >= diaEMA[0]){
         cruza = GlobalVar::CRUZA_ARRIBA;
      }
   } else if(MathMax(velas[0].open, velas[1].close) > diaEMA[0]){
      if(velas[0].close <= diaEMA[0]){
         cruza = GlobalVar::CRUZA_ABAJO;
      }
   }
   
   return cruza;
}

// Ejecuta la orden dependiendo del estado de la estrategia y posición identificada
void EMA150Signal::ejecutarSenal(ExpertSignal* expertSignal){

   //Calcular el ATR y EMA
   double diaATR[2];
   GI.darATR(PERIOD_D1, 14, 0, diaATR);
   
   double diaEMA[2];
   GI.darEMA(PERIOD_D1, totalDias_EMA, 0, diaEMA);
   
   //Calcular valor de velas actual y anterior   
   MqlRates velas[2];
   GI.darVelas(PERIOD_D1, 1, velas);
   
   //Calcular Valores de la Posición
   double precioEntrada = 0;
   double takeProfit = 0;
   double stopLoss = 0;
   int nivelSenal = GlobalVar::STRONG_SIGNAL;
   
   if(posicion == GlobalVar::POSICION_COMPRA){      
      
      //Asigna Precio de entrada
      precioEntrada = GI.darAsk();
      
      //Valida si el precio actual es adecuado para ejecutar orden (con respecto a EMA)
      if(precioEntrada >= diaEMA[0] - (proximidadEMA * diaATR[0])){ 
         
         // Alerta la fuerza de la señal y la entrada ejecutada (con sus características)
         if(precioEntrada >= diaEMA[0] + (separacionEMA * diaATR[0])) nivelSenal = GlobalVar::WEAK_SIGNAL;
         takeProfit = precioEntrada + (stopLossATR * takeProfitProporcion * diaATR[0]);
         stopLoss = precioEntrada - (stopLossATR * diaATR[0]);
         
         expertSignal.setCreateSignal(GlobalVar::BUY_SIGNAL, simbolo, nivelSenal, takeProfit, stopLoss, GlobalVar::NO_STOPVALUE);
      }
   } else {
      //Asigna Precio de entrada
      precioEntrada = GI.darBid();
      
      //Valida si el precio actual es adecuado para ejecutar orden (con respecto a EMA)
      if(precioEntrada <= diaEMA[0] + (proximidadEMA * diaATR[0])){
         
         // Alerta la fuerza de la señal y la entrada ejecutada (con sus características)
         if(precioEntrada <= diaEMA[0] - (separacionEMA * diaATR[0])) nivelSenal = GlobalVar::WEAK_SIGNAL;
         takeProfit = precioEntrada  - (stopLossATR * takeProfitProporcion * diaATR[0]);
         stopLoss = precioEntrada  + (stopLossATR * diaATR[0]);
         
         expertSignal.setCreateSignal(GlobalVar::SELL_SIGNAL, simbolo, nivelSenal, takeProfit, stopLoss, GlobalVar::NO_STOPVALUE);
      }
   }
}
