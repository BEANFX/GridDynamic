//+------------------------------------------------------------------+
//|                                                    StochOver.mq5 |
//|                                                  Copyright 2026  |
//+------------------------------------------------------------------+
#property indicator_chart_window
#property indicator_plots 0

//--- Input Parameters for Stochastic
input group "--- Stochastic Settings ---"
input int            InpKPeriod      = 5;          // %K Period
input int            InpDPeriod      = 3;          // %D Period
input int            InpSlowing      = 3;          // Slowing
input ENUM_MA_METHOD InpMAMethod     = MODE_SMA;   // MA Method
input ENUM_STO_PRICE InpPriceField   = STO_LOWHIGH;// Price Field

input group "--- Threshold Settings ---"
input double         InpOverbought   = 75.0;       // Overbought Threshold
input double         InpOversold     = 25.0;       // Oversold Threshold

//--- Global Variables for Handle Stochastic
int handle_M1, handle_M5, handle_M15;

int OnInit()
  {
   handle_M1  = iStochastic(_Symbol, PERIOD_M1, InpKPeriod, InpDPeriod, InpSlowing, InpMAMethod, InpPriceField);
   handle_M5  = iStochastic(_Symbol, PERIOD_M5, InpKPeriod, InpDPeriod, InpSlowing, InpMAMethod, InpPriceField);
   handle_M15 = iStochastic(_Symbol, PERIOD_M15, InpKPeriod, InpDPeriod, InpSlowing, InpMAMethod, InpPriceField);
   
   if(handle_M1 == INVALID_HANDLE || handle_M5 == INVALID_HANDLE || handle_M15 == INVALID_HANDLE)
     {
      Print("Stochastic failed.");
      return(INIT_FAILED);
     }

   CreateLabel("Stoch_M1",  "M1",  70); // M1
   CreateLabel("Stoch_M5",  "M5",  50); // M5
   CreateLabel("Stoch_M15", "M15", 30); // M15

   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   ObjectDelete(0, "Stoch_M1");
   ObjectDelete(0, "Stoch_M5");
   ObjectDelete(0, "Stoch_M15");
   
   IndicatorRelease(handle_M1);
   IndicatorRelease(handle_M5);
   IndicatorRelease(handle_M15);
  }

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
   double stoch_M1[1], stoch_M5[1], stoch_M15[1];
   
   if(CopyBuffer(handle_M1, 0, 0, 1, stoch_M1) < 0) return(0);
   if(CopyBuffer(handle_M5, 0, 0, 1, stoch_M5) < 0) return(0);
   if(CopyBuffer(handle_M15, 0, 0, 1, stoch_M15) < 0) return(0);
   
   UpdateLabelColor("Stoch_M1", stoch_M1[0]);
   UpdateLabelColor("Stoch_M5", stoch_M5[0]);
   UpdateLabelColor("Stoch_M15", stoch_M15[0]);
   
   return(rates_total);
  }
  
void CreateLabel(string name, string tooltip, int x_distance)
  {
   ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_RIGHT_UPPER); 
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x_distance);      
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, 5);
   ObjectSetString(0, name, OBJPROP_TEXT, "l"); 
   ObjectSetString(0, name, OBJPROP_FONT, "Wingdings");           
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 14);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clrGray);             
   ObjectSetString(0, name, OBJPROP_TOOLTIP, tooltip);            
  }

void UpdateLabelColor(string name, double stoch_value)
  {
   // 1. Overbought (> 75)
   if(stoch_value > InpOverbought)
     {
      ObjectSetInteger(0, name, OBJPROP_COLOR, clrLime);
     }
   // 2. Between 50 sampai 75 (> 50)
   else if(stoch_value > 50.0)
     {
      ObjectSetInteger(0, name, OBJPROP_COLOR, clrDarkGreen);
     }
   // 3. Oversold (< 25)
   else if(stoch_value < InpOversold)
     {
      ObjectSetInteger(0, name, OBJPROP_COLOR, clrRed);
     }
   // 4. Between 50 sampai 25 (< 50)
   else if(stoch_value < 50.0)
     {
      ObjectSetInteger(0, name, OBJPROP_COLOR, clrIndianRed);
     }
   else
     {
      ObjectSetInteger(0, name, OBJPROP_COLOR, clrGray); 
     }
  }
//+------------------------------------------------------------------+