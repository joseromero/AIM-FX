//+------------------------------------------------------------------+
//|                                                MoneyManager.mqh  |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
//+------------------------------------------------------------------+
//| Include files                                                    |
//+------------------------------------------------------------------+
#include <Expert\ExpertMoney.mqh>
//+------------------------------------------------------------------+
//| Class CMoneyManager                                              |
//| Purpose: Class for risk and money management.                    |
//+------------------------------------------------------------------+
class CMoneyManager
{
private:

public:
//--- Parametric constructor
                     CMoneyManager(double stopLoss);
//--- Destructor
                    ~CMoneyManager(void);
};
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
void CMoneyManager::CMoneyManager(double stopLoss)
  {
  
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
void CMoneyManager::~CMoneyManager(void)
  {
  
  }
//+------------------------------------------------------------------+
//| Getting lot size for open long position.                         |
//+------------------------------------------------------------------+
