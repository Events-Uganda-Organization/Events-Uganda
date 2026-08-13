package com.eventsuganda.otp.model;

import java.io.Serializable;
import java.util.Objects;

public class UserBlockId implements Serializable {

    private String blockerId;
    private String blockedId;

    public UserBlockId() {}

    public UserBlockId(String blockerId, String blockedId) {
        this.blockerId = blockerId;
        this.blockedId = blockedId;
    }

    public String getBlockerId() { return blockerId; }
    public void setBlockerId(String blockerId) { this.blockerId = blockerId; }

    public String getBlockedId() { return blockedId; }
    public void setBlockedId(String blockedId) { this.blockedId = blockedId; }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof UserBlockId that)) return false;
        return Objects.equals(blockerId, that.blockerId)
            && Objects.equals(blockedId, that.blockedId);
    }

    @Override
    public int hashCode() {
        return Objects.hash(blockerId, blockedId);
    }
}
