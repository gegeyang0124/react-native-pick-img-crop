package com.yalantis.crop.callback;

import android.graphics.RectF;

/**
 * Created by Oleksii Shliama.
 */
public interface OverlayViewChangeListener {

    void onCropRectUpdated(RectF cropRect);

}