//+------------------------------------------------------------------+
//|                                                       Signal.mqh |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"

#include <AIM-FX\Common\Global\GlobalVar.mqh>

class ExpertSignal{

   private:
   
      //--------------------------------------------------------------+
      //Internal Attributes
      //--------------------------------------------------------------+
      
      // Indicates message for corresponding signal (Create, Update, Stop)
      int signalMessage;
      
      // Indicates the corresponding Ticket id in case it is a open Position / Order. When create message, ticketId = -1
      ulong ticketId;
      
      // Indicates what type of signal it is. For creation purposes (Buy, Sell, Buy Stop, Sell Stop)
      int createSignalType;
      
      // Indicates the asociated asset symbol
      string symbol;
      
      // Indicates the level (strength) of the signal
      int signalLevel;
      
      // Indicates the Take Profit (level)
      double takeProfit;
      
      // Indicates the Stop Loss (level)
      double stopLoss;
      
      // Indicates the Stop Value (level) in case it is a Buy Stop or Sell Stop Signal
      double stopValue;
      
   public:
   
      //--------------------------------------------------------------+
      //Constructor
      //--------------------------------------------------------------+
      
      //Class Constructor - NO_Message on signalMessage by default
      ExpertSignal();
      
      //--------------------------------------------------------------+
      //Auxiliary Methods
      //--------------------------------------------------------------+
      
      //Set Method - you should required fields for a create signal
      void setCreateSignal(int p_createSignalType, string p_symbol, int p_signalLevel, int p_takeProfit, int p_stopLoss, int p_stopValue);
      
      //Set Method - you should required fields for a update signal
      void setUpdateSignal(ulong p_ticketId, string p_symbol, int p_takeProfit, int p_stopLoss);
      
      //Set Method - you should required fields for a close (delete) signal
      void setCloseSignal(ulong p_ticketId, string p_symbol);
      
      //Get Methods
      int getSignalMessage();
      int getCreateSignalType();
      ulong getTicketId();
      string getSymbol();
      int getSignalLevel();
      double getTakeProfit();
      double getStopLoss();
      double getStopValue();      
   
};

//Class Constructor - NO_Message on signalMessage by default
ExpertSignal::ExpertSignal(){
   signalMessage = GlobalVar::NO_MESSAGE;
}

//Set Method - you should required fields for a create signal
void ExpertSignal::setCreateSignal(int p_createSignalType, string p_symbol, int p_signalLevel, int p_takeProfit, int p_stopLoss, int p_stopValue){
   signalMessage = GlobalVar::CREATE_MESSAGE;
   createSignalType = p_createSignalType;
   symbol = p_symbol;
   signalLevel = p_signalLevel;
   takeProfit = p_takeProfit;
   stopLoss = p_stopLoss;
   stopValue = p_stopValue;
}

//Set Method - you should required fields for a update signal
void ExpertSignal::setUpdateSignal(ulong p_ticketId, string p_symbol, int p_takeProfit, int p_stopLoss){
   signalMessage = GlobalVar::UPDATE_MESSAGE;
   ticketId = p_ticketId;
   symbol = p_symbol;
   takeProfit = p_takeProfit;
   stopLoss = p_stopLoss;
}

//Set Method - you should required fields for a close (delete) signal
void ExpertSignal::setCloseSignal(ulong p_ticketId, string p_symbol){
   signalMessage = GlobalVar::CLOSE_MESSAGE;
   ticketId = p_ticketId;
   symbol = p_symbol;
}

//Get Methods
int ExpertSignal::getSignalMessage(){
   return signalMessage;
}

ulong ExpertSignal::getTicketId(){
   return ticketId;
}

int ExpertSignal::getCreateSignalType(){
   return createSignalType;
}

string ExpertSignal::getSymbol(){
   return symbol;
}

int ExpertSignal::getSignalLevel(){
   return signalLevel;
}

double ExpertSignal::getTakeProfit(){
   return takeProfit;
}

double ExpertSignal::getStopLoss(){
   return stopLoss;
}

double ExpertSignal::getStopValue(){
   return stopValue;
}
