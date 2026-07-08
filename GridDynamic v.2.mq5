//+------------------------------------------------------------------+
//|                                              Grid_HL_Dynamic.mq5 |
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

enum ENUM_HL_VISUAL {
   HL_VISUAL_ARROW = 0, // Arrows
   HL_VISUAL_DOT   = 1  // Dots
};

enum ENUM_FILTER_TYPE {
   FILTER_NONE = 0, // No Filter
   FILTER_FIVE = 1, // FIVE
   FILTER_ZERO = 2  // ZERO
};

enum ENUM_COMPARE_MODE {
   COMPARE_BODY = 0, // Body (Open/Close)
   COMPARE_TAIL = 1  // Tail (High/Low)
};

enum ENUM_LABEL_POSITION {
   POSITION_EDGE = 0,  // Edge
   POSITION_MIDDLE = 1 // Middle
};

// --- INPUT PARAMETERS ---
input group "=== MAIN SETTINGS ==="
input ENUM_BASE_PERIOD InpBasePeriod = BASE_M15;
input ENUM_HL_MODE      InpHLMode        = HL_MODE_TAIL; 
input bool              InpMod15         = false; 
input int                  InpLookBackDays = 7;
input int                  InpRefreshOffset = 5;

input group "=== EXTRAS ==="
input ENUM_FILTER_TYPE  InpFilterType    = FILTER_NONE; // M15 Five-Zero

input group "=== SIGNAL BOX SETTINGS ==="
input bool              InpShowSignalBox = true;    
input ENUM_SIGNAL_TYPE  InpSignalType    = SIG_ARROW;      
input bool              InpFilterSignal  = true;      
input color              InpBoxBullColor  = clrLime;
input color              InpBoxBearColor  = clrRed; 
input color              InpBoxNeutralColor = clrGray;
input color              InpBoxFalseColor = clrYellow; 
input int                InpBoxNeutralThreshold = 1000;
input int                InpBoxGap        = 30;

input group "=== SHORTER RANGE SETTINGS ==="
input bool              InpCompareRange     = true; 
input ENUM_COMPARE_MODE InpCompareCalcMode  = COMPARE_BODY;
input color              InpBoxShorterColor  = clrDarkOrange;

input group "=== SUB-GRID SETTINGS (M10/M30) ==="
input bool              InpShowSubGrid  = false;
input color              InpSubGridColor = clrGray;    
input ENUM_LINE_STYLE   InpSubGridStyle = STYLE_DOT;   

input group "=== INFO LABEL SETTINGS ==="
input bool              InpShowLabel    = true;   
input ENUM_LABEL_POSITION InpLabelPosition = POSITION_EDGE;
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
input int                InpHLArrowGap   = 10;     
input color              InpHLHighColor  = clrLime;
input color              InpHLLowColor   = clrRed;

// --- FUNCTIONS ---

void ClearObjects() {
   ObjectsDeleteAll(0, "GridDyn_");
   ObjectsDeleteAll(0, "ForwardGrid_");
   ObjectsDeleteAll(0, "SubGrid_");
   ObjectsDeleteAll(0, "GridM10_");
   ObjectsDeleteAll(0, "InpHalf30_");
   ObjectsDeleteAll(0, "H_");
   ObjectsDeleteAll(0, "L_");
   ObjectsDeleteAll(0, "SigBox_");
   ObjectDelete(0, "Grid_Info_Label");
}

void CreateInfoLabel(string text) {
   string name = "Grid_Info_Label";
   
   if(ObjectFind(0, name) < 0) {
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
   }
   
   // Mengatur Posisi Label Berdasarkan Pilihan Input
   if(InpLabelPosition == POSITION_MIDDLE) {
      int chartWidth = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);
      int middleX = chartWidth / 2;
      
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_TOP); // Diubah ke ANCHOR_TOP agar respon jarak vertikal seimbang dengan Edge
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, middleX);
   } else {
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_RIGHT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, InpLabelXOffset);
   }
   
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, InpLabelYOffset); // Berfungsi presisi memberikan jarak dari atas layar
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, InpLabelSize);
   ObjectSetInteger(0, name, OBJPROP_COLOR, InpLabelColor);
}

// Helper function to get standard timeframe from seconds
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
   if(seconds <= 2592000)  return PERIOD_MN1;
   return PERIOD_MN1; // Fallback untuk BASE_YEAR karena MT5 tidak memiliki PERIOD_YEAR
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
   
   if(PeriodSeconds(_Period) > baseSec) { ClearObjects(); return(rates_total); }

   datetime cycleStart = (datetime)(currentTime - (currentTime % (datetime)baseSec));
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

   long secGrid = baseSec;
   if(InpBasePeriod == BASE_M15 && InpMod15) secGrid = 1800;
   
   long multiplier = 1;
   if(InpBasePeriod == BASE_DAY || InpBasePeriod == BASE_WEEK) multiplier = 7; 
   else if(InpBasePeriod == BASE_MONTH) multiplier = 31;
   else if(InpBasePeriod == BASE_YEAR) multiplier = 365;
   
   datetime lookBack = (datetime)(currentTime - (InpLookBackDays * multiplier * 86400));
   int dynamicTextSize = 8 + (InpHLArrowSize - 1) * 2;
   int sigBoxSize = (InpHLArrowSize > 3) ? InpHLArrowSize - 3 : 1; 

   for(int i = rates_total - limit; i < rates_total; i++) {
      if(i < 0 || time[i] < lookBack) continue;
      
      datetime tGrid = (datetime)(time[i] - (time[i] % (datetime)secGrid));
      string sfx = (string)((long)tGrid);
      bool skipHLandBox = false;
      MqlDateTime dt;
      TimeToStruct(tGrid, dt);
      
      if(InpFilterType == FILTER_FIVE && (dt.min == 0 || dt.min == 30)) skipHLandBox = true;
      else if(InpFilterType == FILTER_ZERO && (dt.min == 15 || dt.min == 45)) skipHLandBox = true;

      if(InpShowGrid) {
         string gn = "GridDyn_" + sfx;
         if(ObjectFind(0, gn) < 0) ObjectCreate(0, gn, OBJ_VLINE, 0, tGrid, 0);
         ObjectSetInteger(0, gn, OBJPROP_COLOR, InpGridColor);
         ObjectSetInteger(0, gn, OBJPROP_STYLE, InpGridStyle);
         ObjectSetInteger(0, gn, OBJPROP_BACK, true);

         if(InpShowSubGrid) {
            if(InpBasePeriod == BASE_M10 && (tGrid % 1800 == 0)) {
               string sgn = "SubGrid_" + sfx;
               if(ObjectFind(0, sgn) < 0) ObjectCreate(0, sgn, OBJ_VLINE, 0, tGrid, 0);
               ObjectSetInteger(0, sgn, OBJPROP_COLOR, InpSubGridColor);
               ObjectSetInteger(0, sgn, OBJPROP_STYLE, InpSubGridStyle);
            }
            else if(InpBasePeriod == BASE_M30) {
               datetime tMid = tGrid + (14 * 60); 
               string sgnMid = "SubGrid_" + (string)((long)tMid);
               if(ObjectFind(0, sgnMid) < 0) ObjectCreate(0, sgnMid, OBJ_VLINE, 0, tMid, 0);
               ObjectSetInteger(0, sgnMid, OBJPROP_COLOR, InpSubGridColor);
               ObjectSetInteger(0, sgnMid, OBJPROP_STYLE, InpSubGridStyle);
            }
         }

         // SIGNAL BOX & SHORT CANDLE DETECTION (Dinamis untuk semua BASE)
         if(!skipHLandBox) {
            datetime tBox = 0;
            ENUM_TIMEFRAMES refTF = PERIOD_CURRENT;
            bool canProcess = false;

            if(InpBasePeriod == BASE_M30) { tBox = tGrid + (25 * 60); refTF = PERIOD_M30; canProcess = true; }
            else if(InpBasePeriod == BASE_M20) { tBox = tGrid + (16 * 60); refTF = PERIOD_M20; canProcess = true; }
            else if(InpBasePeriod == BASE_M15) { tBox = tGrid + (13 * 60); refTF = PERIOD_M15; canProcess = true; }
            else if(InpBasePeriod == BASE_H4 && _Period == PERIOD_M5) { tBox = tGrid + (180 * 60); refTF = PERIOD_H4; canProcess = true; }
            else if(InpBasePeriod == BASE_M10 && _Period == PERIOD_M1) { tBox = tGrid + (9 * 60); refTF = PERIOD_M1; canProcess = true; }
            else if(InpBasePeriod == BASE_H2 && _Period == PERIOD_M5) { tBox = tGrid + (115 * 60); refTF = PERIOD_H2; canProcess = true; }
            else if(InpBasePeriod == BASE_M5 && _Period == PERIOD_M1) { tBox = tGrid + (4 * 60); refTF = PERIOD_M1; canProcess = true; }
            else if(InpBasePeriod >= BASE_H1) {
               refTF = GetTimeframeFromSeconds(baseSec);
               
               // Penempatan tBox berdasarkan hitungan candle M1 yang ditentukan
               if(InpBasePeriod == BASE_H1)        tBox = tGrid + (45 * 60);
               else if(InpBasePeriod == BASE_H4)   tBox = tGrid + (180 * 60);
               else if(InpBasePeriod == BASE_DAY)  tBox = tGrid + (1080 * 60);   
               else if(InpBasePeriod == BASE_WEEK) tBox = tGrid + (5400 * 60);   
               else if(InpBasePeriod == BASE_MONTH) tBox = tGrid + (23760 * 60); 
               else if(InpBasePeriod == BASE_YEAR) tBox = tGrid + (285120 * 60);
               else                                tBox = tGrid + (datetime)(baseSec - PeriodSeconds(_Period));
               
               canProcess = true;
            }

            if(canProcess && tBox > 0) {
               int idxRef = iBarShift(_Symbol, refTF, tGrid, false);
               if(idxRef != -1) {
                  double refOpen = iOpen(_Symbol, refTF, idxRef);
                  double refClose = iClose(_Symbol, refTF, idxRef);
                  double refHigh = iHigh(_Symbol, refTF, idxRef);
                  double refLow = iLow(_Symbol, refTF, idxRef);
                  
                  // HL Detection for Signal Filtering
                  int s_m1_box = iBarShift(_Symbol, PERIOD_M1, tGrid, false);
                  int e_m1_box = iBarShift(_Symbol, PERIOD_M1, (datetime)(tGrid + secGrid - 60), false);
                  datetime tH_Ref=0, tL_Ref=0;
                  if(s_m1_box != -1 && e_m1_box != -1) {
                     tH_Ref = iTime(_Symbol, PERIOD_M1, iHighest(_Symbol, PERIOD_M1, MODE_HIGH, s_m1_box-e_m1_box+1, e_m1_box));
                     tL_Ref = iTime(_Symbol, PERIOD_M1, iLowest(_Symbol, PERIOD_M1, MODE_LOW, s_m1_box-e_m1_box+1, e_m1_box));
                  }

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

                  // Compare Range Logic
                  bool isShorter = false;
                  if(InpCompareRange && InpBasePeriod != BASE_M10) {
                     datetime tPrevGrid = tGrid - (datetime)secGrid;
                     int idxPrev = iBarShift(_Symbol, refTF, tPrevGrid, false);
                     if(idxPrev != -1) {
                        double currentR = (InpCompareCalcMode == COMPARE_BODY) ? bodySize : (refHigh - refLow);
                        double prevR = (InpCompareCalcMode == COMPARE_BODY) ? MathAbs(iOpen(_Symbol,refTF,idxPrev)-iClose(_Symbol,refTF,idxPrev)) : (iHigh(_Symbol,refTF,idxPrev)-iLow(_Symbol,refTF,idxPrev));
                        if(currentR < prevR) { isShorter = true; boxColor = InpBoxShorterColor; }
                     }
                  }

                  // Visual Output Logic
                  int finalCode = -1;
                  if(InpShowSignalBox) {
                     if(InpSignalType == SIG_ARROW) finalCode = (tH_Ref < tL_Ref) ? 0xEE : 0xEC;
                     else finalCode = 110;
                  } else if(isShorter) {
                     finalCode = 0xAA; // Wingdings AA (Dot) only if shorter
                  }

                  if(finalCode != -1) {
                     double offset = InpBoxGap * _Point;
                     double pLev = (tH_Ref < tL_Ref) ? refHigh + offset : refLow - offset;
                     ENUM_ARROW_ANCHOR anchor = (tH_Ref < tL_Ref) ? ANCHOR_BOTTOM : ANCHOR_TOP;
                     
                     // SIG_BOX manual adjustment
                     if(InpShowSignalBox && InpSignalType == SIG_BOX) {
                        pLev = (refClose >= refOpen) ? refHigh + offset : refLow - offset;
                        anchor = (refClose >= refOpen) ? ANCHOR_BOTTOM : ANCHOR_TOP;
                     }

                     string sbName = "SigBox_" + (string)((long)tBox);
                     if(ObjectCreate(0, sbName, OBJ_ARROW, 0, tBox, pLev)) {
                        ObjectSetInteger(0, sbName, OBJPROP_ARROWCODE, finalCode);
                        ObjectSetInteger(0, sbName, OBJPROP_COLOR, boxColor);
                        ObjectSetInteger(0, sbName, OBJPROP_ANCHOR, anchor);
                        ObjectSetInteger(0, sbName, OBJPROP_WIDTH, (InpShowSignalBox) ? sigBoxSize : InpHLArrowSize);
                     }
                  }
               }
            }
         }
      }

      if(!skipHLandBox && InpShowHLArrows) {
          double absH = 0, absL = 0; datetime tH = 0, tL = 0;
          int s_m1 = iBarShift(_Symbol, PERIOD_M1, tGrid, false);
          int e_m1 = iBarShift(_Symbol, PERIOD_M1, (datetime)(tGrid + secGrid - 60), false);
          if(s_m1 != -1 && e_m1 != -1) {
              int count = s_m1 - e_m1 + 1;
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
              
              double aGap = InpHLArrowGap * _Point * 10;
              string hn="H_"+sfx, ln="L_"+sfx;
              int codeH = (InpHLVisual == HL_VISUAL_ARROW) ? 241 : 0xA0;
              int codeL = (InpHLVisual == HL_VISUAL_ARROW) ? 242 : 0xA0;
              ObjectCreate(0,hn,OBJ_ARROW,0,tH,absH+aGap);
              ObjectSetInteger(0,hn,OBJPROP_ARROWCODE,codeH); ObjectSetInteger(0,hn,OBJPROP_COLOR,InpHLHighColor);
              ObjectSetInteger(0,hn,OBJPROP_ANCHOR,ANCHOR_BOTTOM); ObjectSetInteger(0,hn,OBJPROP_WIDTH,InpHLArrowSize);
              ObjectCreate(0,ln,OBJ_ARROW,0,tL,absL-aGap);
              ObjectSetInteger(0,ln,OBJPROP_ARROWCODE,codeL); ObjectSetInteger(0,ln,OBJPROP_COLOR,InpHLLowColor);
              ObjectSetInteger(0,ln,OBJPROP_ANCHOR,ANCHOR_TOP); ObjectSetInteger(0,ln,OBJPROP_WIDTH,InpHLArrowSize);
          }
      }
   }

   // --- FORWARD GRID GENERATION (Masa Depan) ---
   if(InpShowGrid && InpShowForwardGrid) {
      datetime currentCycleStart = (datetime)(currentTime - (currentTime % (datetime)secGrid));
      datetime tForwardGrid = currentCycleStart + (datetime)secGrid;
      string fgn = "ForwardGrid_" + (string)((long)tForwardGrid);
      
      if(ObjectFind(0, fgn) < 0) ObjectCreate(0, fgn, OBJ_VLINE, 0, tForwardGrid, 0);
      ObjectSetInteger(0, fgn, OBJPROP_COLOR, InpGridColor);
      ObjectSetInteger(0, fgn, OBJPROP_STYLE, InpGridStyle);
      ObjectSetInteger(0, fgn, OBJPROP_BACK, true);
   } else {
      ObjectsDeleteAll(0, "ForwardGrid_");
   }

   return(rates_total);
}

void OnDeinit(const int reason) { ClearObjects(); }