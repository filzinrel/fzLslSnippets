// SmoothScaleXWithListen.lsl
// Scales only along local X from current → target percentage (0–100%) of gMaxX when receiving a message on chan 1337,
// pinning the negative-X end so it never moves in world space.

// CONFIGURATION
float    gMaxX       = 2.0;     // full-scale at 100%
float    gDuration   = 0.1;     // seconds for any percent transition
integer  gSteps      = 1;      // granularity of animation

// STATE
vector   gBaseSize;             // initial <X,Y,Z> at script load
vector   gCurrentSize;          // working scale <X,Y,Z>
vector   gTargetSize;           // target scale <X,Y,Z>
vector   gAnchorPos;            // world-space anchor on negative-X end
rotation gRot;                  // prim rotation at script load
float    gInterval;             // time between steps
float    gStepX;                // ΔX each tick
float    gPercent;              // current percent of gMaxX (0–100)
float    gDirection = 1.0;      // growth direction: 1.0 = grow, -1.0 = shrink
integer  gCount;
integer  gListenHandle;

// Helper: update debug text with pos, scale, and percent
ShowMetrics()
{
    gPercent = (gCurrentSize.x / gMaxX) * 100.0;
    llSetText(
        "POS:" + (string)llGetPos() +
        " SCL:X=" + (string)gCurrentSize.x +
        " PCT=" + (string)gPercent + "%",
        <1,1,1>,
        1.0
    );
}

// Helper: apply scale and reposition so negative-X end stays fixed
RepositionAndScale()
{
    // 1) scale in X
    llSetScale(gCurrentSize);

    // 2) reposition so the negative-X anchor stays fixed
    vector axis       = llRot2Left(gRot);
    vector halfNow    = <((gCurrentSize.x - gBaseSize.x) * 0.5 * gDirection),0,0>;
    llSetPos(gAnchorPos + halfNow);

    // 3) update debug metrics
    ShowMetrics();
}

default
{
    state_entry()
    {
        // capture initial scale & orientation
        gBaseSize    = llGetScale();
        gCurrentSize = gBaseSize;
        gRot         = llGetRot();

        // compute anchor at negative-X end        
        gAnchorPos      = llGetPos();

        // compute interval
        gInterval = gDuration / (float)gSteps;

        // initial debug text
        ShowMetrics();

        // listen for numeric 0–100 on chan 1337
        gListenHandle = llListen(1337, "", NULL_KEY, "");
    }

    touch_start(integer total_number)
    {
        // fallback: grow to 100%
        gCount       = 0;
        gDirection   = 1.0;
        gTargetSize  = <gMaxX, gBaseSize.y, gBaseSize.z>;
        gStepX       = (gDirection * llFabs(gTargetSize.x - gCurrentSize.x)) / (float)gSteps;
        llSetTimerEvent(gInterval);
    }

    listen(integer channel, string name, key id, string msg)
    {
        // parse numeric percent
        list parts = llParseString2List(msg, [" "], []);
        if (llGetListLength(parts) < 1)
        {
            llOwnerSay("Send a number (0–100) on chan 1337.");
            return;
        }
        string tok = llList2String(parts, 0);
        float raw  = llList2Float(parts, 0);
        if ( raw < 0.0 || raw > 100.0)
        {
            llOwnerSay("Please send a numeric value 0–100.");
            return;
        }
        float pct = raw / 100.0;

        // compute target
        gTargetSize = <(gMaxX * pct), gBaseSize.y, gBaseSize.z>;
        // determine direction using if/else (no ternary ops)
        if (gTargetSize.x >= gCurrentSize.x)
        {
            gDirection = 1.0;
        }
        else
        {
            gDirection = -1.0;
        }

        // prepare animation
        gCount = 0;
        gStepX = (gDirection * llFabs(gTargetSize.x - gCurrentSize.x)) / (float)gSteps;
        llSetTimerEvent(gInterval);
    }

    timer()
    {
        if (gCount < gSteps)
        {
            gCurrentSize.x += gStepX;
            RepositionAndScale();
            gCount++;
        }
        else
        {
            llSetTimerEvent(0.0);
            gCurrentSize.x = gTargetSize.x;
            RepositionAndScale();
        }
    }
}
