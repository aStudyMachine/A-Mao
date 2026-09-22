package cn.studymachine.system.api.dto;

import java.io.Serializable;

/**
 * Dict value cross-module DTO.
 */
public class DictValueDTO implements Serializable {

    private static final long serialVersionUID = 1L;

    private Long id;
    private String dictKey;
    private String value;

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getDictKey() {
        return dictKey;
    }

    public void setDictKey(String dictKey) {
        this.dictKey = dictKey;
    }

    public String getValue() {
        return value;
    }

    public void setValue(String value) {
        this.value = value;
    }
}