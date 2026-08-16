package com.eventsuganda.otp.dto.response;

public class ReviewSummaryResponse {

    private double avgRating;
    private long totalCount;
    private long[] starCounts;

    public ReviewSummaryResponse() {}

    public ReviewSummaryResponse(double avgRating, long totalCount, long[] starCounts) {
        this.avgRating = avgRating;
        this.totalCount = totalCount;
        this.starCounts = starCounts;
    }

    public double getAvgRating() { return avgRating; }
    public void setAvgRating(double avgRating) { this.avgRating = avgRating; }

    public long getTotalCount() { return totalCount; }
    public void setTotalCount(long totalCount) { this.totalCount = totalCount; }

    public long[] getStarCounts() { return starCounts; }
    public void setStarCounts(long[] starCounts) { this.starCounts = starCounts; }
}
