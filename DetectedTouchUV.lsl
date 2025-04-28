// DetectedTouchUV.lsl
// Displays the UV coordinates of a touch on the prim via llSetText.

// Default shader color for the text
vector textColor   = <1.0, 1.0, 1.0>;

default
{
    state_entry()
    {
        // Prompt the user
        llSetText("Touch this prim to get UV coords", textColor, 1.0);
    }

    touch_start(integer total_number)
    {
        if (total_number < 1) return;

        // Get the UV coordinates of the first touch
        vector uv = llDetectedTouchUV(0);

        // Format as string (U,V)
        string uvText = "U=" + (string)uv.x + "  V=" + (string)uv.y;

        // Display the UV coords on the prim
        llSetText(uvText, textColor, 1);
    }
}
