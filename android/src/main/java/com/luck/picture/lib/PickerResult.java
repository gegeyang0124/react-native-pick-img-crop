package com.luck.picture.lib;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.List;

public class PickerResult implements Serializable {
    public List<String> paths=new ArrayList<>();

    public PickerResult(List<String> pathList) {
        this.paths = pathList;
    }

    public List<String> getPaths() {
        return paths;
    }

    public void setPaths(List<String> paths) {
        this.paths = paths;
    }
}
