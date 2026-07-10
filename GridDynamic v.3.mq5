//+------------------------------------------------------------------+
//|                                           Grid_HL_Dynamic.mq5    |
//+------------------------------------------------------------------+
#property indicator_chart_window
#property indicator_plots 0

// --- ENUMERATIONS ---
enum ENUM_BASE_PERIOD {
   BASE_M5   = 300,
   BASE_M10  = 600,
   BASE_M15  = 900,
   BASE_M20  = 1200,
   BASE_M30  = 1800,
   BASE_H1   = 3600,
   BASE_H2   = 7200,
   BASE_H4   = 14400, 
   BASE_DAY  = 86400,   
   BASE_WEEK = 604800,  
   BASE_MONTH = 2592000, 
   BASE_MONTHPLUS = 2592001, 
   BASE_YEAR = 31536000  
};

enum ENUM_HL_MODE {
   HL_MODE_TAIL = 0, // Tail (High/Low)
   HL_MODE_BODY = 1  // Body Candle (Open/Close)
};

enum ENUM_SIGNAL_TYPE {
   SIG_BOX = 0,   // Box 
   SIG_ARROW = 1  // Arrow (Last HL)
};

enum ENUM_LAST_HL_STYLE {
   LAST_HL_DOT     = 0xA0,  // Dot
   LAST_HL_SQUARE  = 0xFA,  // Square
   LAST_HL_DIAMOND = 0x77   // Diamond
};

enum ENUM_HL_VISUAL {
   HL_VISUAL_ARROW = 0, // Arrows
   HL_VISUAL_DOT   = 1  // Dots
};

enum ENUM_FILTER_TYPE {
   FILTER_NONE = 0,     // No Filter
   FILTER_FIVE = 1,     // M15: FIVE
   FILTER_ZERO = 2,     // M15: ZERO
   FILTER_M30_00 = 3,   // M30: 00 (Hanya Menit 00)
   FILTER_M30_30 = 4    // M30: 30 (Hanya Menit 30)
};

enum ENUM_SKIP_M15 {
   SKIP_M15_DISABLE      = 0, // Disable
   SKIP_M15_HIDE_00      = 1, // Hide 00
   SKIP_M15_HIDE_15      = 2, // Hide 15
   SKIP_M15_HIDE_30      = 3, // Hide 30
   SKIP_M15_HIDE_45      = 4, // Hide 45
   SKIP_M15_ONLY_SHOW_00 = 5, // Only Show 00
   SKIP_M15_ONLY_SHOW_15 = 6, // Only Show 15
   SKIP_M15_ONLY_SHOW_30 = 7, // Only Show 30
   SKIP_M15_ONLY_SHOW_45 = 8  // Only Show 45
};

enum ENUM_BOX_SKIP_STATUS {
   BOX_SHOW_NORMAL = 0,
   BOX_SHOW_BLANK  = 1,
   BOX_REMOVE_TOTAL = 2
};

enum ENUM_COMPARE_MODE {
   COMPARE_BODY = 0, // Body (Base)
   COMPARE_TAIL = 1  // Tail (High/Low)
};

enum ENUM_COMPARE_RANGE {
   COMPARE_DISABLE = 0,      // Disable
   COMPARE_SHORTER_PREV = 1, // Shorter than Previous Segment
   COMPARE_LONGER_PREV = 2,  // Longer than Previous Segment
   COMPARE_LONGER_NEXT = 3   // Longer than Next Segment
};

enum ENUM_LABEL_POSITION {
   POSITION_EDGE = 0,  // Edge
   POSITION_MIDDLE = 1 // Middle
};

enum ENUM_FIRST_HOUR_MODE {
   FIRST_HOUR_DISABLED = 0, // Disabled
   FIRST_HOUR_ONLY      = 1, // Only (Show HL ONLY on Min 00)
   FIRST_HOUR_ENABLED   = 2, // Enabled (Orange HL on Min 00)
   FIRST_HOUR_ARROW     = 3, // Only with Arrow (Default SigBox)
   FIRST_HOUR_ONLY_45   = 4  // Only 45 (Show HL ONLY on Min 45)
};

enum ENUM_PT_TYPE {
   PT_TYPE_STAR = 0,   // Star
   PT_TYPE_ARROW = 1   // Arrow
};

enum ENUM_SUBGRID_MODE {
   SUBGRID_DISABLED = 0, // Disabled
   SUBGRID_M30      = 1800, // M30
   SUBGRID_H1       = 3600, // H1
   SUBGRID_H2       = 7200, // H2
   SUBGRID_H4       = 14400 // H4
};

enum ENUM_MA_COMPARE_TF {
   MA_COMP_M1  = 1,  // M1
   MA_COMP_M5  = 5,  // M5
   MA_COMP_M15 = 15, // M15
   MA_COMP_M30 = 30, // M30
   MA_COMP_H1  = 60  // H1
};

enum ENUM_M30_BASE_MODE {
   M30_BASE_DISABLED      = 0, // Disabled
   M30_BASE_ALL_SEGMENTS  = 1, // Enabled
   M30_BASE_ONLY_FALSE    = 2  // Only False
};

// --- INPUT PARAMETERS ---
input group "=== MAIN SETTINGS ==="
input ENUM_BASE_PERIOD InpBasePeriod = BASE_M15;
input ENUM_SUBGRID_MODE InpShowSubGrid  = SUBGRID_H1;
input ENUM_HL_MODE      InpHLMode        = HL_MODE_TAIL;
input bool InpLastHL = false;
input int                   InpLookBackDays = 7;
input int                   InpRefreshOffset = 5;

input group "=== Moving Average (M1 BASED) ==="
input bool              InpShowMA        = true;
input int               InpMAPeriod1     = 20; // MA 1 (Fast)
input int               InpMAPeriod2     = 50; // MA 2 (Slow)
input ENUM_MA_COMPARE_TF InpMACompareTF  = MA_COMP_M1;

input group "=== EXTRAS ==="
input ENUM_FILTER_TYPE     InpFilterType    = FILTER_NONE;      
input ENUM_SKIP_M15        InpSkipM15       = SKIP_M15_DISABLE;
input bool                 InpNullCandle    = false;                
input ENUM_FIRST_HOUR_MODE InpFirstHour     = FIRST_HOUR_DISABLED; 
input ENUM_M30_BASE_MODE   InpM30BaseMode   = M30_BASE_DISABLED; // BASE_M30

input group "=== PEAK & TROUGH ==="
input bool                 InpShowPeakTrough = false;              
input ENUM_PT_TYPE         InpPeakTroughType = PT_TYPE_STAR;       
input int                  InpPrevSegmen     = 1;                  
input int                  InpNextSegmen     = 1;                  
input int                  InpPTBreakThreshold = 0;                

input group "=== SIGNAL BOX SETTINGS ==="
input bool              InpShowSignalBox = false;    
input ENUM_SIGNAL_TYPE  InpSignalType    = SIG_ARROW;      
input bool              InpFilterSignal  = true;      
input color             InpBoxBullColor  = clrLime;
input color             InpBoxBearColor  = clrRed; 
input color             InpBoxNeutralColor = clrGray;
input color             InpBoxFalseColor = clrMediumSlateBlue; 
input int                InpBoxNeutralThreshold = 110;
input int                InpBoxGap        = 30;

input group "=== SHORTER / COMPARE RANGE SETTINGS ==="
input ENUM_COMPARE_RANGE InpCompareRange     = COMPARE_DISABLE; 
input ENUM_COMPARE_MODE  InpCompareCalcMode  = COMPARE_BODY;
input color              InpBoxShorterColor  = clrDarkOrange;

input group "=== SUB-GRID SETTINGS ==="
input color              InpSubGridColor = clrCadetBlue;    
input ENUM_LINE_STYLE   InpSubGridStyle = STYLE_DOT;   

input group "=== INFO LABEL SETTINGS ==="
input bool              InpShowLabel    = true;   
input ENUM_LABEL_POSITION InpLabelPosition = POSITION_MIDDLE; 
input color              InpLabelColor   = clrDarkOrange;
input int                InpLabelXOffset = 8;     
input int                InpLabelYOffset = 8;     
input int                InpLabelSize    = 8;     

input group "=== GRID SETTINGS ==="
input bool              InpShowGrid     = true;
input bool              InpShowForwardGrid = true;
input color              InpGridColor    = clrDarkSlateGray;
input ENUM_LINE_STYLE   InpGridStyle    = STYLE_DOT;

input group "=== HL SCANNER SETTINGS (M1 BASED) ==="
input bool              InpShowHLArrows = true;
input ENUM_HL_VISUAL    InpHLVisual     = HL_VISUAL_DOT;
input int                InpHLArrowSize  = 1;      
input int                InpHLArrowGap   = 0;     
input color              InpHLHighColor  = clrLime;
input color              InpHLLowColor   = clrRed;

input group "=== LAST HL SETTING ==="
input color              InpLastHLColor       = clrDarkOrange;
input ENUM_LAST_HL_STYLE InpLastHLStyle       = LAST_HL_SQUARE;


// --- GLOBAL VARIABLES FOR MA ---
int handleMA_M5       = INVALID_HANDLE;
int handleMA_M15      = INVALID_HANDLE;
int handleMA_M30      = INVALID_HANDLE;
int handleMA_H1       = INVALID_HANDLE;

// Handle Dinamis khusus untuk kalkulasi perbandingan warna M5
int handleComp_Fast   = INVALID_HANDLE;
int handleComp_Slow   = INVALID_HANDLE;

// --- FUNCTIONS ---

void ClearObjects() {
   ObjectsDeleteAll(0, "GridDyn_");
   ObjectsDeleteAll(0, "ForwardGrid_");
   ObjectsDeleteAll(0, "SubGrid_");
   ObjectsDeleteAll(0, "ForwardSubGrid_");
   ObjectsDeleteAll(0, "GridM10_");
   ObjectsDeleteAll(0, "InpHalf30_");
   ObjectsDeleteAll(0, "H_");
   ObjectsDeleteAll(0, "L_");
   ObjectsDeleteAll(0, "SigBox_");
   ObjectsDeleteAll(0, "SigBoxM30_");
   ObjectDelete(0, "Grid_Info_Label");
   
   ObjectDelete(0, "GridMA_M5");
   ObjectDelete(0, "GridMA_M15");
   ObjectDelete(0, "GridMA_M30");
   ObjectDelete(0, "GridMA_H1");
}

void CreateInfoLabel(string text) {
   string name = "Grid_Info_Label";
   
   if(ObjectFind(0, name) < 0) {
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
   }
   
   if(InpLabelPosition == POSITION_MIDDLE) {
      int chartWidth = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);
      int middleX = chartWidth / 2;
            
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_TOP); 
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, middleX);
   } else {
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_RIGHT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, InpLabelXOffset);
   }
   
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, InpLabelYOffset); 
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, InpLabelSize);
   ObjectSetInteger(0, name, OBJPROP_COLOR, InpLabelColor);
}

ENUM_TIMEFRAMES GetTimeframeFromSeconds(long seconds) {
   if(seconds <= 60)       return PERIOD_M1;
   if(seconds <= 300)      return PERIOD_M5;
   if(seconds <= 600)      return PERIOD_M10;
   if(seconds <= 900)      return PERIOD_M15;
   if(seconds <= 1200)     return PERIOD_M20;
   if(seconds <= 1800)     return PERIOD_M30;
   if(seconds <= 3600)     return PERIOD_H1;
   if(seconds <= 7200)     return PERIOD_H2;
   if(seconds <= 14400)    return PERIOD_H4;
   if(seconds <= 86400)    return PERIOD_D1;
   if(seconds <= 604800)   return PERIOD_W1;
   return PERIOD_MN1; 
}

datetime GetStartOfMonth(datetime timeVal) {
   MqlDateTime dt;
   TimeToStruct(timeVal, dt);
   dt.day = 1;
   dt.hour = 0;
   dt.min = 0;
   dt.sec = 0;
   return StructToTime(dt);
}

long GetSecondsInMonth(datetime timeVal) {
   MqlDateTime dt;
   TimeToStruct(timeVal, dt);
   
   int year = dt.year;
   int mon = dt.mon;
   
   int daysInMonth = 31;
   if(mon == 4 || mon == 6 || mon == 9 || mon == 11) daysInMonth = 30;
   else if(mon == 2) {
      bool isLeap = (year % 4 == 0 && (year % 100 != 0 || year % 400 == 0));
      daysInMonth = isLeap ? 29 : 28;
   }
   return (long)daysInMonth * 86400;
}

ENUM_BOX_SKIP_STATUS GetSkipM15BoxStatus(int barMin) {
   if(InpBasePeriod != BASE_M15 || InpSkipM15 == SKIP_M15_DISABLE) return BOX_SHOW_NORMAL;
   
   if(InpSkipM15 == SKIP_M15_HIDE_30 && barMin == 30) return BOX_REMOVE_TOTAL;
   
   if(InpSkipM15 == SKIP_M15_HIDE_00 && barMin == 0)  return BOX_SHOW_BLANK;
   if(InpSkipM15 == SKIP_M15_HIDE_15 && barMin == 15) return BOX_SHOW_BLANK;
   if(InpSkipM15 == SKIP_M15_HIDE_45 && barMin == 45) return BOX_SHOW_BLANK;
   
   if(InpSkipM15 == SKIP_M15_ONLY_SHOW_00 && barMin != 0)  return BOX_SHOW_BLANK;
   if(InpSkipM15 == SKIP_M15_ONLY_SHOW_15 && barMin != 15) return BOX_SHOW_BLANK;
   if(InpSkipM15 == SKIP_M15_ONLY_SHOW_30 && barMin != 30) return BOX_SHOW_BLANK;
   if(InpSkipM15 == SKIP_M15_ONLY_SHOW_45 && barMin != 45) return BOX_SHOW_BLANK;
   
   return BOX_SHOW_NORMAL;
}

bool IsSkipM15HLTriggered(int barMin) {
   if(InpBasePeriod != BASE_M15 || InpSkipM15 == SKIP_M15_DISABLE) return false;
   
   if(InpSkipM15 == SKIP_M15_HIDE_30 && barMin == 30) return false; 
   
   if(InpSkipM15 == SKIP_M15_HIDE_00 && barMin == 0)  return true;
   if(InpSkipM15 == SKIP_M15_HIDE_15 && barMin == 15) return true;
   if(InpSkipM15 == SKIP_M15_HIDE_45 && barMin == 45) return true;
   
   if(InpSkipM15 == SKIP_M15_ONLY_SHOW_00 && barMin != 0)  return true;
   if(InpSkipM15 == SKIP_M15_ONLY_SHOW_15 && barMin != 15) return true;
   if(InpSkipM15 == SKIP_M15_ONLY_SHOW_30 && barMin != 30) return true;
   if(InpSkipM15 == SKIP_M15_ONLY_SHOW_45 && barMin != 45) return true;
   
   return false;
}

// Helper untuk hitung Range murni (Body/Tail) berbasis data M1 dalam satu segmen penuh
double CalculateSegmentRangeM1(datetime tStart, long duration, ENUM_COMPARE_MODE mode) {
   int s_m1 = iBarShift(_Symbol, PERIOD_M1, tStart, false);
   int e_m1 = iBarShift(_Symbol, PERIOD_M1, (datetime)(tStart + duration - 60), false);
   if(s_m1 == -1 || e_m1 == -1) return 0.0;
   
   int count = s_m1 - e_m1 + 1;
   if(count <= 0) return 0.0;
   
   if(mode == COMPARE_TAIL) {
      int hIdx = iHighest(_Symbol, PERIOD_M1, MODE_HIGH, count, e_m1);
      int lIdx = iLowest(_Symbol, PERIOD_M1, MODE_LOW, count, e_m1);
      if(hIdx != -1 && lIdx != -1) {
         return (iHigh(_Symbol, PERIOD_M1, hIdx) - iLow(_Symbol, PERIOD_M1, lIdx));
      }
   } else { // COMPARE_BODY: Mencari Max Body High dan Min Body Low murni dari M1
      double maxBodyHigh = -1.0;
      double minBodyLow  = 999999.0;
      for(int k = e_m1; k <= s_m1; k++) {
         double bMax = MathMax(iOpen(_Symbol, PERIOD_M1, k), iClose(_Symbol, PERIOD_M1, k));
         double bMin = MathMin(iOpen(_Symbol, PERIOD_M1, k), iClose(_Symbol, PERIOD_M1, k));
         if(bMax > maxBodyHigh) maxBodyHigh = bMax;
         if(bMin < minBodyLow)  minBodyLow  = bMin;
      }
      if(maxBodyHigh > 0 && minBodyLow < 999999.0) {
         return (maxBodyHigh - minBodyLow);
      }
   }
   return 0.0;
}

// --- INITIALIZATION ---
int OnInit() {
   handleMA_M5      = iMA(_Symbol, PERIOD_M5,  InpMAPeriod1, 0, MODE_SMA, PRICE_CLOSE);
   handleMA_M15     = iMA(_Symbol, PERIOD_M15, InpMAPeriod1, 0, MODE_SMA, PRICE_CLOSE);
   handleMA_M30     = iMA(_Symbol, PERIOD_M30, InpMAPeriod1, 0, MODE_SMA, PRICE_CLOSE);
   handleMA_H1      = iMA(_Symbol, PERIOD_H1,  InpMAPeriod1, 0, MODE_SMA, PRICE_CLOSE);
   
   ENUM_TIMEFRAMES compTF = PERIOD_M5;
   switch(InpMACompareTF) {
      case MA_COMP_M1:  compTF = PERIOD_M1;  break;
      case MA_COMP_M5:  compTF = PERIOD_M5;  break;
      case MA_COMP_M15: compTF = PERIOD_M15; break;
      case MA_COMP_M30: compTF = PERIOD_M30; break;
      case MA_COMP_H1:  compTF = PERIOD_H1;  break;
   }
   
   handleComp_Fast = iMA(_Symbol, compTF, InpMAPeriod1, 0, MODE_SMA, PRICE_CLOSE);
   handleComp_Slow = iMA(_Symbol, compTF, InpMAPeriod2, 0, MODE_SMA, PRICE_CLOSE);
   
   return(INIT_SUCCEEDED);
}

// --- MAIN ---
int OnCalculate(const int rates_total, const int prev_calculated, const datetime &time[],
                const double &open[], const double &high[], const double &low[],
                const double &close[], const long &tick_volume[], const long &volume[],
                const int &spread[])
{
   static datetime lastRefreshCycle = 0;
   datetime currentTime = TimeCurrent();
   long baseSec = (long)InpBasePeriod;
   
   long checkSec = (InpBasePeriod == BASE_MONTHPLUS) ? 2592000 : baseSec;
   if(PeriodSeconds(_Period) > checkSec) { ClearObjects(); return(rates_total); }

   if(_Period == PERIOD_M1 && InpShowMA && rates_total > 0) {
      datetime currentBarTime = time[rates_total - 1];
      double maValues[4] = {0.0, 0.0, 0.0, 0.0};
      string maNames[4]  = {"GridMA_M5", "GridMA_M15", "GridMA_M30", "GridMA_H1"};
      int maHandles[4]   = {handleMA_M5, handleMA_M15, handleMA_M30, handleMA_H1};
      
      for(int m = 0; m < 4; m++) {
         if(maHandles[m] != INVALID_HANDLE) {
            double buff[1];
            if(CopyBuffer(maHandles[m], 0, 0, 1, buff) > 0) {
               maValues[m] = buff[0];
               
               if(ObjectFind(0, maNames[m]) < 0) {
                  ObjectCreate(0, maNames[m], OBJ_ARROW, 0, currentBarTime, maValues[m]);
               } else {
                  ObjectMove(0, maNames[m], 0, currentBarTime, maValues[m]);
               }
               
               ObjectSetInteger(0, maNames[m], OBJPROP_ARROWCODE, 0x73); 
               
               color finalMaColor = clrDarkSlateGray;
               
               if(maNames[m] == "GridMA_M5" && handleComp_Fast != INVALID_HANDLE && handleComp_Slow != INVALID_HANDLE) {
                  double buffFast[1];
                  double buffSlow[1];
                  if(CopyBuffer(handleComp_Fast, 0, 0, 1, buffFast) > 0 && CopyBuffer(handleComp_Slow, 0, 0, 1, buffSlow) > 0) {
                     if(buffFast[0] > buffSlow[0])      finalMaColor = clrLime;
                     else if(buffFast[0] < buffSlow[0]) finalMaColor = clrRed;
                  }
               }
               
               ObjectSetInteger(0, maNames[m], OBJPROP_COLOR, finalMaColor);
               ObjectSetInteger(0, maNames[m], OBJPROP_ANCHOR, ANCHOR_CENTER);
               ObjectSetInteger(0, maNames[m], OBJPROP_WIDTH, InpHLArrowSize);
            }
         }
      }
   } else {
      ObjectDelete(0, "GridMA_M5");
      ObjectDelete(0, "GridMA_M15");
      ObjectDelete(0, "GridMA_M30");
      ObjectDelete(0, "GridMA_H1");
   }

   datetime cycleStart = 0;
   if(InpBasePeriod == BASE_MONTHPLUS) {
      cycleStart = GetStartOfMonth(currentTime);
   } else {
      cycleStart = (datetime)(currentTime - (currentTime % (datetime)baseSec));
   }
   
   datetime targetRefreshTime = cycleStart + InpRefreshOffset;
   
   bool isRefreshTime = false;
   if(currentTime >= targetRefreshTime && lastRefreshCycle != cycleStart) {
      isRefreshTime = true;
      lastRefreshCycle = cycleStart;
   }

   if(prev_calculated > 0 && !isRefreshTime) return(rates_total); 

   int limit;
   if(prev_calculated == 0 || isRefreshTime) { ClearObjects(); limit = rates_total; }
   else { limit = rates_total - prev_calculated + 1; }

   if(InpShowLabel) {
      string fullEnum = EnumToString(InpBasePeriod); 
      string cleanName = StringSubstr(fullEnum, 5); 
      CreateInfoLabel("BASE " + cleanName);
   } else ObjectDelete(0, "Grid_Info_Label");

   long multiplier = 1;
   if(InpBasePeriod == BASE_DAY || InpBasePeriod == BASE_WEEK) multiplier = 7; 
   else if(InpBasePeriod == BASE_MONTH || InpBasePeriod == BASE_MONTHPLUS) multiplier = 31;
   else if(InpBasePeriod == BASE_YEAR) multiplier = 365;
   
   datetime lookBack = (datetime)(currentTime - (InpLookBackDays * multiplier * 86400));
   int dynamicTextSize = 8 + (InpHLArrowSize - 1) * 2;
   int sigBoxSize = (InpHLArrowSize > 3) ? InpHLArrowSize - 3 : 1; 

   long secGrid = (InpBasePeriod == BASE_MONTHPLUS) ? 2592000 : baseSec;

   for(int i = rates_total - limit; i < rates_total; i++) {
      if(i < 0 || time[i] < lookBack) continue;
      
      datetime tGrid = 0;
      if(InpBasePeriod == BASE_MONTHPLUS) {
         tGrid = GetStartOfMonth(time[i]);
         secGrid = GetSecondsInMonth(time[i]);
      } else {
         secGrid = baseSec;
         tGrid = (datetime)(time[i] - (time[i] % (datetime)secGrid));
      }
      
      string sfx = (string)((long)tGrid);
      bool skipHLandBox = false;
      bool triggerNullCandleVisual = false; 
      color nullCandleColor = clrDarkGray;   
      MqlDateTime dt;
      TimeToStruct(tGrid, dt);
      
      if(InpFilterType == FILTER_FIVE && (dt.min == 0 || dt.min == 30)) skipHLandBox = true;
      else if(InpFilterType == FILTER_ZERO && (dt.min == 15 || dt.min == 45)) skipHLandBox = true;
      else if(InpFilterType == FILTER_M30_00 && dt.min == 30) skipHLandBox = true;
      else if(InpFilterType == FILTER_M30_30 && dt.min == 0) skipHLandBox = true;

      if((InpFirstHour == FIRST_HOUR_ONLY || InpFirstHour == FIRST_HOUR_ARROW) && dt.min != 0) {
         skipHLandBox = true;
      }
      else if(InpFirstHour == FIRST_HOUR_ONLY_45 && dt.min != 45) {
         skipHLandBox = true;
      }

      if(!skipHLandBox && InpNullCandle) {
         ENUM_TIMEFRAMES refTF_Null = (InpBasePeriod == BASE_MONTHPLUS) ? PERIOD_MN1 : GetTimeframeFromSeconds(baseSec);
         int idxCurr = iBarShift(_Symbol, refTF_Null, tGrid, false);
         
         if(idxCurr != -1) {
            datetime tPrevGrid = 0;
            if(InpBasePeriod == BASE_MONTHPLUS) {
               tPrevGrid = GetStartOfMonth(tGrid - 5 * 86400); 
            } else {
               tPrevGrid = tGrid - (datetime)secGrid;
            }
            
            int idxPrev = iBarShift(_Symbol, refTF_Null, tPrevGrid, false);
            if(idxPrev != -1) {
               double cHigh = iHigh(_Symbol, refTF_Null, idxCurr);
               double cLow  = iLow(_Symbol, refTF_Null, idxCurr);
               double pHigh = iHigh(_Symbol, refTF_Null, idxPrev);
               double pLow  = iLow(_Symbol, refTF_Null, idxPrev);
               
               bool isInside = (cHigh <= pHigh && cLow >= pLow);
               bool isOutside = (cHigh > pHigh && cLow < pLow);
               
               if(isInside || isOutside) {
                  triggerNullCandleVisual = true; 
                  
                  if(isInside) {
                     skipHLandBox = true;       
                     nullCandleColor = clrDarkGray;
                  }
                  else if(isOutside) {
                     skipHLandBox = false;      
                     nullCandleColor = clrSnow;
                  }
               }
            }
         }
      }

      bool subGridDrawn = false;
      if(InpShowSubGrid != SUBGRID_DISABLED && PeriodSeconds(_Period) < (long)InpShowSubGrid) {
         if((long)time[i] % (long)InpShowSubGrid == 0) {
            string sgn = "SubGrid_" + (string)((long)time[i]);
            if(ObjectFind(0, sgn) < 0) ObjectCreate(0, sgn, OBJ_VLINE, 0, time[i], 0);
            ObjectSetInteger(0, sgn, OBJPROP_COLOR, InpSubGridColor);
            ObjectSetInteger(0, sgn, OBJPROP_STYLE, InpSubGridStyle);
            ObjectSetInteger(0, sgn, OBJPROP_BACK, true);
            subGridDrawn = true;
         }
      }

      if(InpShowGrid) {
         string gn = "GridDyn_" + sfx;
         if(subGridDrawn && time[i] == tGrid) {
            if(ObjectFind(0, gn) >= 0) ObjectDelete(0, gn);
         } else if(time[i] == tGrid) {
            if(ObjectFind(0, gn) < 0) ObjectCreate(0, gn, OBJ_VLINE, 0, tGrid, 0);
            ObjectSetInteger(0, gn, OBJPROP_COLOR, InpGridColor);
            ObjectSetInteger(0, gn, OBJPROP_STYLE, InpGridStyle);
            ObjectSetInteger(0, gn, OBJPROP_BACK, true);
         }

         // Ambil status skip box untuk iterasi ini
         ENUM_BOX_SKIP_STATUS boxSkipStatus = GetSkipM15BoxStatus(dt.min);

         if(!skipHLandBox || triggerNullCandleVisual) {
            datetime tBox = 0;
            ENUM_TIMEFRAMES refTF = PERIOD_CURRENT;
            bool canProcess = false;

            if(InpBasePeriod == BASE_M30) { tBox = (datetime)((long)tGrid + (25 * 60)); refTF = PERIOD_M30; canProcess = true; }
            else if(InpBasePeriod == BASE_M20) { tBox = (datetime)((long)tGrid + (16 * 60)); refTF = PERIOD_M20; canProcess = true; }
            else if(InpBasePeriod == BASE_M15) { tBox = (datetime)((long)tGrid + (13 * 60)); refTF = PERIOD_M15; canProcess = true; }
            else if(InpBasePeriod == BASE_H4 && _Period == PERIOD_M5) { tBox = (datetime)((long)tGrid + (180 * 60)); refTF = PERIOD_H4; canProcess = true; }
            else if(InpBasePeriod == BASE_M10) { tBox = (datetime)((long)tGrid + (9 * 60)); refTF = PERIOD_M10; canProcess = true; }
            else if(InpBasePeriod == BASE_H2 && _Period == PERIOD_M5) { tBox = (datetime)((long)tGrid + (115 * 60)); refTF = PERIOD_H2; canProcess = true; }
            else if(InpBasePeriod == BASE_M5 && _Period == PERIOD_M1) { tBox = (datetime)((long)tGrid + (4 * 60)); refTF = PERIOD_M1; canProcess = true; }
            else if(InpBasePeriod >= BASE_H1 || InpBasePeriod == BASE_MONTHPLUS) {
               refTF = (InpBasePeriod == BASE_MONTHPLUS) ? PERIOD_MN1 : GetTimeframeFromSeconds(baseSec);
               
               if(InpBasePeriod == BASE_H1)          tBox = (datetime)((long)tGrid + (45 * 60));
               else if(InpBasePeriod == BASE_H4)     tBox = (datetime)((long)tGrid + (180 * 60));
               else if(InpBasePeriod == BASE_DAY)    tBox = (datetime)((long)tGrid + (1080 * 60));   
               else if(InpBasePeriod == BASE_WEEK)   tBox = (datetime)((long)tGrid + (5400 * 60));   
               else if(InpBasePeriod == BASE_MONTH)  tBox = (datetime)((long)tGrid + (23760 * 60)); 
               else if(InpBasePeriod == BASE_MONTHPLUS) tBox = (datetime)((long)tGrid + (secGrid - 86400)); 
               else if(InpBasePeriod == BASE_YEAR)   tBox = (datetime)((long)tGrid + (285120 * 60));
               else                                  tBox = (datetime)((long)tGrid + (baseSec - PeriodSeconds(_Period)));
               
               canProcess = true;
            }

            // JIKA STATUSNYA REMOVE_TOTAL, SEGMEN INI TIDAK AKAN MEMPROSES PEMBUATAN BOX SAMA SEKALI
            if(canProcess && tBox > 0 && boxSkipStatus != BOX_REMOVE_TOTAL) {
               int idxRef = iBarShift(_Symbol, refTF, tGrid, false);
               if(idxRef != -1) {
                  double refOpen = iOpen(_Symbol, refTF, idxRef);
                  double refClose = iClose(_Symbol, refTF, idxRef);
                  double refHigh = iHigh(_Symbol, refTF, idxRef);
                  double refLow = iLow(_Symbol, refTF, idxRef);
                  
                  int s_m1_box = iBarShift(_Symbol, PERIOD_M1, tGrid, false);
                  int e_m1_box = iBarShift(_Symbol, PERIOD_M1, (datetime)(tGrid + secGrid - 60), false);
                  datetime tH_Ref=0, tL_Ref=0;
                  if(s_m1_box != -1 && e_m1_box != -1) {
                     tH_Ref = iTime(_Symbol, PERIOD_M1, iHighest(_Symbol, PERIOD_M1, MODE_HIGH, s_m1_box-e_m1_box+1, e_m1_box));
                     tL_Ref = iTime(_Symbol, PERIOD_M1, iLowest(_Symbol, PERIOD_M1, MODE_LOW, s_m1_box-e_m1_box+1, e_m1_box));
                  }

                  double offset = InpBoxGap * _Point;
                  double pLev = (tH_Ref < tL_Ref) ? refHigh + offset : refLow - offset;
                  ENUM_ARROW_ANCHOR anchor = (tH_Ref < tL_Ref) ? ANCHOR_BOTTOM : ANCHOR_TOP;

                  bool isPeak = false;
                  bool isTrough = false;
                  bool isBreakBothPrev = false; 
                  
                  if(InpShowPeakTrough) {
                     if(s_m1_box != -1 && e_m1_box != -1) {
                        double hCurr = iHigh(_Symbol, PERIOD_M1, iHighest(_Symbol, PERIOD_M1, MODE_HIGH, s_m1_box-e_m1_box+1, e_m1_box));
                        double lCurr = iLow(_Symbol, PERIOD_M1, iLowest(_Symbol, PERIOD_M1, MODE_LOW, s_m1_box-e_m1_box+1, e_m1_box));

                        bool passPrevPeak = true;
                        bool passPrevTrough = true;
                        double ptThresh = InpPTBreakThreshold * _Point;
                        
                        int prevLoops = (InpPrevSegmen < 1) ? 1 : InpPrevSegmen;
                        for(int p = 1; p <= prevLoops; p++) {
                           datetime tPrevGrid = 0;
                           long secPrev = secGrid;
                           
                           if(InpBasePeriod == BASE_MONTHPLUS) {
                              tPrevGrid = GetStartOfMonth(tGrid - (35 * p) * 86400);
                              secPrev = GetSecondsInMonth(tPrevGrid);
                           } else {
                              tPrevGrid = (datetime)((long)tGrid - (secGrid * p));
                           }
                           
                           int s_m1_prev = iBarShift(_Symbol, PERIOD_M1, tPrevGrid, false);
                           int e_m1_prev = iBarShift(_Symbol, PERIOD_M1, (datetime)(tPrevGrid + secPrev - 60), false);
                           
                           if(s_m1_prev != -1 && e_m1_prev != -1) {
                              double hPrev = iHigh(_Symbol, PERIOD_M1, iHighest(_Symbol, PERIOD_M1, MODE_HIGH, s_m1_prev-e_m1_prev+1, e_m1_prev));
                              double lPrev = iLow(_Symbol, PERIOD_M1, iLowest(_Symbol, PERIOD_M1, MODE_LOW, s_m1_prev-e_m1_prev+1, e_m1_prev));
                              
                              if((hCurr - hPrev) < ptThresh) passPrevPeak = false;
                              if((lPrev - lCurr) < ptThresh) passPrevTrough = false;
                              
                              if(p == 1 && (hCurr - hPrev) >= ptThresh && (lPrev - lCurr) >= ptThresh) {
                                 isBreakBothPrev = true;
                              }
                           } else {
                              passPrevPeak = false;
                              passPrevTrough = false;
                           }
                        }
                        
                        bool passNextPeak = true;
                        bool passNextTrough = true;
                        
                        int loops = (InpNextSegmen < 1) ? 1 : InpNextSegmen;
                        for(int n = 1; n <= loops; n++) {
                           datetime tNextGrid = 0;
                           long secNext = secGrid;
                           
                           if(InpBasePeriod == BASE_MONTHPLUS) {
                              tNextGrid = GetStartOfMonth(tGrid + (35 * n) * 86400);
                              secNext = GetSecondsInMonth(tNextGrid);
                           } else {
                              tNextGrid = (datetime)((long)tGrid + (secGrid * n));
                           }
                           
                           int s_m1_next = iBarShift(_Symbol, PERIOD_M1, tNextGrid, false);
                           int e_m1_next = iBarShift(_Symbol, PERIOD_M1, (datetime)(tNextGrid + secNext - 60), false);
                           
                           if(s_m1_next != -1 && e_m1_next != -1) {
                              double hNext = iHigh(_Symbol, PERIOD_M1, iHighest(_Symbol, PERIOD_M1, MODE_HIGH, s_m1_next-e_m1_next+1, e_m1_next));
                              double lNext = iLow(_Symbol, PERIOD_M1, iLowest(_Symbol, PERIOD_M1, MODE_LOW, s_m1_next-e_m1_next+1, e_m1_next));
                              
                              if(hCurr <= hNext) passNextPeak = false;
                              if(lCurr >= lNext) passNextTrough = false;
                           } else {
                              passNextPeak = false;
                              passNextTrough = false;
                           }
                        }
                        
                        isPeak   = (passPrevPeak && passNextPeak);
                        isTrough = (passPrevTrough && passNextTrough);
                     }
                  }

                  if(isPeak || isTrough) {
                     string sbName = "SigBox_" + (string)((long)tBox);
                     int codePT = 0;
                     color colorPT = clrNONE;
                     
                     if(isPeak && isTrough) {
                        codePT = 0xAA;
                        colorPT = clrMediumSlateBlue;
                     } 
                     else if(InpPeakTroughType == PT_TYPE_STAR) {
                        codePT = 0xAA;
                        colorPT = clrYellow;
                     } else {
                        if(isPeak) {
                           codePT = 0xEE;
                           colorPT = (isBreakBothPrev) ? clrMediumSlateBlue : clrRed;
                        } else {
                           codePT = 0xEC;
                           colorPT = (isBreakBothPrev) ? clrMediumSlateBlue : clrLime;
                        }
                     }

                     // Pengecekan Fitur: Skip M15 untuk Peak & Trough (Box)
                     if(boxSkipStatus == BOX_SHOW_BLANK) {
                        codePT = 0xFB;
                     }

                     if(ObjectCreate(0, sbName, OBJ_ARROW, 0, tBox, pLev)) {
                        ObjectSetInteger(0, sbName, OBJPROP_ARROWCODE, codePT); 
                        ObjectSetInteger(0, sbName, OBJPROP_COLOR, colorPT); 
                        ObjectSetInteger(0, sbName, OBJPROP_ANCHOR, anchor);
                        ObjectSetInteger(0, sbName, OBJPROP_WIDTH, InpHLArrowSize);
                     }
                  }
                  else if(InpFirstHour == FIRST_HOUR_ONLY && dt.min == 0) {
                     string sbName = "SigBox_" + (string)((long)tBox);
                     int codeFH = 0xAA;
                     
                     // Pengecekan Fitur: Skip M15 untuk First Hour Only (Box)
                     if(boxSkipStatus == BOX_SHOW_BLANK) {
                        codeFH = 0xFB;
                     }

                     if(ObjectCreate(0, sbName, OBJ_ARROW, 0, tBox, pLev)) {
                        ObjectSetInteger(0, sbName, OBJPROP_ARROWCODE, codeFH); 
                        color selectedColor = (dt.hour % 4 == 0) ? clrSeashell : clrDarkOrange;
                        ObjectSetInteger(0, sbName, OBJPROP_COLOR, selectedColor); 
                        ObjectSetInteger(0, sbName, OBJPROP_ANCHOR, anchor);
                        ObjectSetInteger(0, sbName, OBJPROP_WIDTH, InpHLArrowSize);
                     }
                  }
                  else if(triggerNullCandleVisual) {
                     string sbName = "SigBox_" + (string)((long)tBox);
                     int codeNC = 0xAA;
                     
                     // Pengecekan Fitur: Skip M15 untuk Null Candle (Box)
                     if(boxSkipStatus == BOX_SHOW_BLANK) {
                        codeNC = 0xFB;
                     }

                     if(ObjectCreate(0, sbName, OBJ_ARROW, 0, tBox, pLev)) {
                        ObjectSetInteger(0, sbName, OBJPROP_ARROWCODE, codeNC); 
                        ObjectSetInteger(0, sbName, OBJPROP_COLOR, nullCandleColor); 
                        ObjectSetInteger(0, sbName, OBJPROP_ANCHOR, anchor);
                        ObjectSetInteger(0, sbName, OBJPROP_WIDTH, InpHLArrowSize);
                     }
                  }
                  else {
                     color boxColor = clrNONE;
                     double bodySize = MathAbs(refClose - refOpen);
                     double threshold = InpBoxNeutralThreshold * _Point;
                     
                     if(bodySize < threshold) boxColor = InpBoxNeutralColor;
                     else if(refClose > refOpen) boxColor = InpBoxBullColor;
                     else boxColor = InpBoxBearColor;

                     if(InpFilterSignal && boxColor != InpBoxNeutralColor) {
                        if(boxColor == InpBoxBullColor && tH_Ref <= tL_Ref) boxColor = InpBoxFalseColor;
                        else if(boxColor == InpBoxBearColor && tL_Ref <= tH_Ref) boxColor = InpBoxFalseColor;
                     }

                     bool isMatchCompare = false;
                     if(InpCompareRange != COMPARE_DISABLE) {
                        // Ambil range segmen saat ini
                        double currentR = CalculateSegmentRangeM1(tGrid, secGrid, InpCompareCalcMode);
                        
                        if(InpCompareRange == COMPARE_SHORTER_PREV || InpCompareRange == COMPARE_LONGER_PREV) {
                           datetime tPrevGrid = 0;
                           long secPrev = secGrid;
                           if(InpBasePeriod == BASE_MONTHPLUS) {
                              tPrevGrid = GetStartOfMonth(tGrid - 5 * 86400); 
                              secPrev = GetSecondsInMonth(tPrevGrid);
                           } else {
                              tPrevGrid = (datetime)((long)tGrid - secGrid);
                           }
                           
                           double prevR = CalculateSegmentRangeM1(tPrevGrid, secPrev, InpCompareCalcMode);
                           
                           if(InpCompareRange == COMPARE_SHORTER_PREV && currentR < prevR) {
                              isMatchCompare = true;
                              boxColor = InpBoxShorterColor;
                           }
                           else if(InpCompareRange == COMPARE_LONGER_PREV && currentR > prevR) {
                              isMatchCompare = true;
                              boxColor = InpBoxShorterColor;
                           }
                        }
                        else if(InpCompareRange == COMPARE_LONGER_NEXT) {
                           datetime tNextGrid = 0;
                           long secNext = secGrid;
                           if(InpBasePeriod == BASE_MONTHPLUS) {
                              tNextGrid = GetStartOfMonth(tGrid + 35 * 86400); 
                              secNext = GetSecondsInMonth(tNextGrid);
                           } else {
                              tNextGrid = (datetime)((long)tGrid + secGrid);
                           }
                           
                           // Kondisi hanya dievaluasi jika segmen berikutnya sudah terbentuk
                           if(tNextGrid < currentTime) {
                              double nextR = CalculateSegmentRangeM1(tNextGrid, secNext, InpCompareCalcMode);
                              if(currentR > nextR) {
                                 isMatchCompare = true;
                                 boxColor = InpBoxShorterColor;
                              }
                           }
                        }
                     }

                     int finalCode = -1;
                     if(InpShowSignalBox) {
                        finalCode = (InpSignalType == SIG_ARROW) ? ((tH_Ref < tL_Ref) ? 0xEE : 0xEC) : 110;
                     } else if(isMatchCompare) {
                        finalCode = 0xAA; 
                     }

                     // Pengecekan Fitur: Skip M15 untuk Tampilan Regulasi Normal (Box)
                     if(finalCode != -1 && boxSkipStatus == BOX_SHOW_BLANK) {
                        finalCode = 0xFB;
                     }

                     if(finalCode != -1) {
                        if(InpShowSignalBox && InpSignalType == SIG_BOX && finalCode != 0xFB) {
                           pLev = (refClose >= refOpen) ? refHigh + offset : refLow - offset;
                           anchor = (refClose >= refOpen) ? ANCHOR_BOTTOM : ANCHOR_TOP;
                        }

                        string sbName = "SigBox_" + (string)((long)tBox);
                        if(ObjectCreate(0, sbName, OBJ_ARROW, 0, tBox, pLev)) {
                           ObjectSetInteger(0, sbName, OBJPROP_ARROWCODE, finalCode);
                           ObjectSetInteger(0, sbName, OBJPROP_COLOR, boxColor);
                           ObjectSetInteger(0, sbName, OBJPROP_ANCHOR, anchor);
                           ObjectSetInteger(0, sbName, OBJPROP_WIDTH, (InpShowSignalBox && finalCode != 0xFB) ? sigBoxSize : InpHLArrowSize);
                        }
                     }
                  }
               }
            }
         }
      }

      // --- VISUAL ADDITION: BASE_M30 PREVIEW ON BASE_M15 AND PERIOD_M1 ---
      if(InpM30BaseMode != M30_BASE_DISABLED && InpBasePeriod == BASE_M15 && _Period == PERIOD_M1) {
         datetime tGridM30 = (datetime)(time[i] - (time[i] % 1800));
         int idxM30 = iBarShift(_Symbol, PERIOD_M30, tGridM30, false);
         
         if(idxM30 != -1) {
            double m30Open  = iOpen(_Symbol, PERIOD_M30, idxM30);
            double m30Close = iClose(_Symbol, PERIOD_M30, idxM30);
            double m30High  = iHigh(_Symbol, PERIOD_M30, idxM30);
            double m30Low   = iLow(_Symbol, PERIOD_M30, idxM30);
            
            int s_m1_m30 = iBarShift(_Symbol, PERIOD_M1, tGridM30, false);
            int e_m1_m30 = iBarShift(_Symbol, PERIOD_M1, (datetime)(tGridM30 + 1800 - 60), false);
            datetime tH_M30 = 0, tL_M30 = 0;
            
            if(s_m1_m30 != -1 && e_m1_m30 != -1) {
               tH_M30 = iTime(_Symbol, PERIOD_M1, iHighest(_Symbol, PERIOD_M1, MODE_HIGH, s_m1_m30 - e_m1_m30 + 1, e_m1_m30));
               tL_M30 = iTime(_Symbol, PERIOD_M1, iLowest(_Symbol, PERIOD_M1, MODE_LOW, s_m1_m30 - e_m1_m30 + 1, e_m1_m30));
            }
            
            color m30BoxColor = clrNONE;
            double m30BodySize = MathAbs(m30Close - m30Open);
            double m30Threshold = InpBoxNeutralThreshold * _Point;
            
            if(m30BodySize < m30Threshold) m30BoxColor = InpBoxNeutralColor;
            else if(m30Close > m30Open) m30BoxColor = InpBoxBullColor;
            else m30BoxColor = InpBoxBearColor;
            
            if(InpFilterSignal && m30BoxColor != InpBoxNeutralColor) {
               if(m30BoxColor == InpBoxBullColor && tH_M30 <= tL_M30) m30BoxColor = InpBoxFalseColor;
               else if(m30BoxColor == InpBoxBearColor && tL_M30 <= tH_M30) m30BoxColor = InpBoxFalseColor;
            }
            
            bool drawPreview = false;
            int finalM30Code = 0x74; 
            color finalM30Color = m30BoxColor; 
            
            if(InpM30BaseMode == M30_BASE_ALL_SEGMENTS) {
               drawPreview = true;
            }
            else if(InpM30BaseMode == M30_BASE_ONLY_FALSE && m30BoxColor == InpBoxFalseColor) {
               drawPreview = true;
               finalM30Code = 0xAA; 
               finalM30Color = clrDarkOrange; 
            }
            
            if(drawPreview) {
               double m30Offset = InpBoxGap * _Point;
               double pLevM30 = (tH_M30 < tL_M30) ? m30High + m30Offset : m30Low - m30Offset;
               ENUM_ARROW_ANCHOR anchorM30 = (tH_M30 < tL_M30) ? ANCHOR_BOTTOM : ANCHOR_TOP;
               
               datetime tBoxM30_X16 = tGridM30 + (16 * 60);
               string m30ObjName = "SigBoxM30_" + (string)((long)tBoxM30_X16);
               
               if(ObjectCreate(0, m30ObjName, OBJ_ARROW, 0, tBoxM30_X16, pLevM30)) {
                  ObjectSetInteger(0, m30ObjName, OBJPROP_ARROWCODE, finalM30Code);
                  ObjectSetInteger(0, m30ObjName, OBJPROP_COLOR, finalM30Color);
                  ObjectSetInteger(0, m30ObjName, OBJPROP_ANCHOR, anchorM30);
                  ObjectSetInteger(0, m30ObjName, OBJPROP_WIDTH, sigBoxSize);
               }
            }
         }
      }

      // --- HL SCANNER ---
      if(!skipHLandBox && InpShowHLArrows) {
         bool allowDrawHL = true;
         if((InpFirstHour == FIRST_HOUR_ONLY || InpFirstHour == FIRST_HOUR_ARROW) && dt.min != 0) allowDrawHL = false;
         else if(InpFirstHour == FIRST_HOUR_ONLY_45 && dt.min != 45)                             allowDrawHL = false;
         if(IsSkipM15HLTriggered(dt.min))                                                        allowDrawHL = false;
         
         if(allowDrawHL) {
             double absH = 0, absL = 0; datetime tH = 0, tL = 0;
             datetime tH_Tail = 0, tL_Tail = 0; // Khusus untuk pencatatan berbasis tail
             
             int s_m1 = iBarShift(_Symbol, PERIOD_M1, tGrid, false);
             int e_m1 = iBarShift(_Symbol, PERIOD_M1, (datetime)(tGrid + secGrid - 60), false);
             
             if(s_m1 != -1 && e_m1 != -1) {
                 int count = s_m1 - e_m1 + 1;
                 
                 // --- 1. SCANNING DATA NORMAL (Mengikuti Input User) ---
                 if(InpHLMode == HL_MODE_TAIL) {
                     int hIdx = iHighest(_Symbol, PERIOD_M1, MODE_HIGH, count, e_m1);
                     int lIdx = iLowest(_Symbol, PERIOD_M1, MODE_LOW, count, e_m1);
                     tH = iTime(_Symbol, PERIOD_M1, hIdx); tL = iTime(_Symbol, PERIOD_M1, lIdx);
                 } else {
                     double scanH = -1.0, scanL = 999999.0;
                     for(int k=e_m1; k<=s_m1; k++) {
                         double bMax = MathMax(iOpen(_Symbol,PERIOD_M1,k), iClose(_Symbol,PERIOD_M1,k));
                         double bMin = MathMin(iOpen(_Symbol,PERIOD_M1,k), iClose(_Symbol,PERIOD_M1,k));
                         if(bMax > scanH) { scanH = bMax; tH = iTime(_Symbol,PERIOD_M1,k); }
                         if(bMin < scanL) { scanL = bMin; tL = iTime(_Symbol,PERIOD_M1,k); }
                     }
                 }
                 absH = iHigh(_Symbol, PERIOD_M1, iBarShift(_Symbol, PERIOD_M1, tH));
                 absL = iLow(_Symbol, PERIOD_M1, iBarShift(_Symbol, PERIOD_M1, tL));
                 
                 // --- 2. SCANNING DATA KHUSUS TAIL (Selalu Tail untuk Fitur Last HL) ---
                 int hIdxTail = iHighest(_Symbol, PERIOD_M1, MODE_HIGH, count, e_m1);
                 int lIdxTail = iLowest(_Symbol, PERIOD_M1, MODE_LOW, count, e_m1);
                 tH_Tail = iTime(_Symbol, PERIOD_M1, hIdxTail); 
                 tL_Tail = iTime(_Symbol, PERIOD_M1, lIdxTail);
                 double absH_Tail = iHigh(_Symbol, PERIOD_M1, hIdxTail);
                 double absL_Tail = iLow(_Symbol, PERIOD_M1, lIdxTail);
                 
  // --- 3. THEME DEFAULT & FILTER LAST HL ---
                 color finalHighColor = InpHLHighColor;
                 color finalLowColor  = InpHLLowColor;
                 
                 if(!InpLastHL && ((InpFirstHour == FIRST_HOUR_ENABLED || InpFirstHour == FIRST_HOUR_ONLY) && dt.min == 0)) {
                     finalHighColor = clrDarkOrange; finalLowColor  = clrDarkOrange;
                 }
                 
                 double aGap = InpHLArrowGap * _Point * 10; 
                 string hn="H_"+sfx, ln="L_"+sfx;
                 string lastObjName = "LastHL_" + sfx;
                 int codeH = (InpHLVisual == HL_VISUAL_ARROW) ? 241 : 0xA0;
                 int codeL = (InpHLVisual == HL_VISUAL_ARROW) ? 242 : 0xA0;
                 
                 // Variabel flag untuk mendeteksi apakah HL normal berada di candle yang sama dengan LastHL
                 bool hideNormalHigh = false;
                 bool hideNormalLow  = false;
                 
                 // Tentukan dulu waktu (candle) dan posisi di mana LastHL seharusnya berada
                 datetime tLastHL_Target = 0;
                 bool isLastHL_AtHigh = false;
                 
                 if(InpLastHL) {
                     if(tH_Tail < tL_Tail) {
                         // High terjadi duluan, Low terjadi paling AKHIR
                         tLastHL_Target = tL_Tail;
                         isLastHL_AtHigh = false;
                     } 
                     else if(tL_Tail < tH_Tail) {
                         // Low terjadi duluan, High terjadi paling AKHIR
                         tLastHL_Target = tH_Tail;
                         isLastHL_AtHigh = true;
                     }
                     
                     // Evaluasi kecocokan candle (Sembunyikan Hanya Jika Bertepatan di Candle yang Sama)
                     if(isLastHL_AtHigh && tH == tLastHL_Target) hideNormalHigh = true;
                     if(!isLastHL_AtHigh && tL == tLastHL_Target) hideNormalLow = true;
                 }
                 
                 // --- PROSES CETAK / HAPUS HIGH NORMAL ---
                 if(!hideNormalHigh) {
                     if(ObjectFind(0, hn) < 0) {
                         ObjectCreate(0, hn, OBJ_ARROW, 0, tH, absH + aGap);
                     } else {
                         ObjectMove(0, hn, 0, tH, absH + aGap);
                     }
                     ObjectSetInteger(0, hn, OBJPROP_ARROWCODE, codeH); 
                     ObjectSetInteger(0, hn, OBJPROP_COLOR, finalHighColor);
                     ObjectSetInteger(0, hn, OBJPROP_ANCHOR, ANCHOR_BOTTOM); 
                     ObjectSetInteger(0, hn, OBJPROP_WIDTH, InpHLArrowSize);
                 } else {
                     ObjectDelete(0, hn); // Sembunyikan (Hapus) karena bertepatan di candle yang sama
                 }
                 
                 // --- PROSES CETAK / HAPUS LOW NORMAL ---
                 if(!hideNormalLow) {
                     if(ObjectFind(0, ln) < 0) {
                         ObjectCreate(0, ln, OBJ_ARROW, 0, tL, absL - aGap);
                     } else {
                         ObjectMove(0, ln, 0, tL, absL - aGap);
                     }
                     ObjectSetInteger(0, ln, OBJPROP_ARROWCODE, codeL); 
                     ObjectSetInteger(0, ln, OBJPROP_COLOR, finalLowColor);
                     ObjectSetInteger(0, ln, OBJPROP_ANCHOR, ANCHOR_TOP); 
                     ObjectSetInteger(0, ln, OBJPROP_WIDTH, InpHLArrowSize);
                 } else {
                     ObjectDelete(0, ln); // Sembunyikan (Hapus) karena bertepatan di candle yang sama
                 }
                 
// --- 4. PROSES CETAK SAKELAR OVERLAY LAST HL ---
                 if(InpLastHL && tLastHL_Target > 0) {
                     // Ambil kode Wingdings dari input setting user
                     int finalLastHLCode = (int)InpLastHLStyle; 
                     
                     if(!isLastHL_AtHigh) {
                         // Cetak Custom Shape menimpa posisi Low Terakhir (Tail)
                         if(ObjectFind(0, lastObjName) < 0) {
                             ObjectCreate(0, lastObjName, OBJ_ARROW, 0, tLastHL_Target, absL_Tail - aGap);
                         } else {
                             ObjectMove(0, lastObjName, 0, tLastHL_Target, absL_Tail - aGap);
                         }
                         ObjectSetInteger(0, lastObjName, OBJPROP_ARROWCODE, finalLastHLCode); 
                         ObjectSetInteger(0, lastObjName, OBJPROP_COLOR, InpLastHLColor);
                         ObjectSetInteger(0, lastObjName, OBJPROP_ANCHOR, ANCHOR_TOP);
                         ObjectSetInteger(0, lastObjName, OBJPROP_WIDTH, InpHLArrowSize);
                     } 
                     else {
                         // Cetak Custom Shape menimpa posisi High Terakhir (Tail)
                         if(ObjectFind(0, lastObjName) < 0) {
                             ObjectCreate(0, lastObjName, OBJ_ARROW, 0, tLastHL_Target, absH_Tail + aGap);
                         } else {
                             ObjectMove(0, lastObjName, 0, tLastHL_Target, absH_Tail + aGap);
                         }
                         ObjectSetInteger(0, lastObjName, OBJPROP_ARROWCODE, finalLastHLCode); 
                         ObjectSetInteger(0, lastObjName, OBJPROP_COLOR, InpLastHLColor);
                         ObjectSetInteger(0, lastObjName, OBJPROP_ANCHOR, ANCHOR_BOTTOM);
                         ObjectSetInteger(0, lastObjName, OBJPROP_WIDTH, InpHLArrowSize);
                     }
                 } else {
                     ObjectDelete(0, lastObjName);
                 }
             }
         }
      }
   }

   // --- FORWARD GRID & FORWARD SUB-GRID GENERATION ---
   if(InpShowGrid && InpShowForwardGrid) {
      datetime tForwardGrid = 0;
      if(InpBasePeriod == BASE_MONTHPLUS) {
         MqlDateTime currentDt;
         TimeToStruct(currentTime, currentDt);
         currentDt.mon++;
         if(currentDt.mon > 12) { currentDt.mon = 1; currentDt.year++; }
         currentDt.day = 1; currentDt.hour = 0; currentDt.min = 0; currentDt.sec = 0;
         tForwardGrid = StructToTime(currentDt);
      } else {
         datetime currentCycleStart = (datetime)(currentTime - (currentTime % (datetime)secGrid));
         tForwardGrid = (datetime)((long)currentCycleStart + secGrid);
      }
      
      datetime tForwardSubGrid = 0;
      bool hasForwardSubGrid = false;
      
      if(InpShowSubGrid != SUBGRID_DISABLED && PeriodSeconds(_Period) < (long)InpShowSubGrid) {
         datetime currentSubGridStart = (datetime)(currentTime - (currentTime % (long)InpShowSubGrid));
         tForwardSubGrid = (datetime)((long)currentSubGridStart + (long)InpShowSubGrid);
         hasForwardSubGrid = true;
      }

      string fgn = "ForwardGrid_" + (string)((long)tForwardGrid);
      if(hasForwardSubGrid && tForwardSubGrid == tForwardGrid) {
         if(ObjectFind(0, fgn) >= 0) ObjectDelete(0, fgn);
      } else {
         if(ObjectFind(0, fgn) < 0) ObjectCreate(0, fgn, OBJ_VLINE, 0, tForwardGrid, 0);
         ObjectSetInteger(0, fgn, OBJPROP_COLOR, InpGridColor);
         ObjectSetInteger(0, fgn, OBJPROP_STYLE, InpGridStyle);
         ObjectSetInteger(0, fgn, OBJPROP_BACK, true);
      }
      
      if(hasForwardSubGrid) {
         string fsgn = "ForwardSubGrid_" + (string)((long)tForwardSubGrid);
         if(ObjectFind(0, fsgn) < 0) ObjectCreate(0, fsgn, OBJ_VLINE, 0, tForwardSubGrid, 0);
         ObjectSetInteger(0, fsgn, OBJPROP_COLOR, InpSubGridColor);
         ObjectSetInteger(0, fsgn, OBJPROP_STYLE, InpSubGridStyle);
         ObjectSetInteger(0, fsgn, OBJPROP_BACK, true);
      } else {
         ObjectsDeleteAll(0, "ForwardSubGrid_");
      }
   } else {
      ObjectsDeleteAll(0, "ForwardGrid_");
      ObjectsDeleteAll(0, "ForwardSubGrid_");
   }

   return(rates_total);
}

void OnDeinit(const int reason) { ClearObjects(); }
//+------------------------------------------------------------------+