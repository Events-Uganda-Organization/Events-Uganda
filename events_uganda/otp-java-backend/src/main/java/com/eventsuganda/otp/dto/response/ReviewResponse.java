package com.eventsuganda.otp.dto.response;

public class ReviewResponse {

    private String id;
    private String userName;
    private String userImageUrl;
    private String reviewText;
    private String date;
    private int rating;

    public ReviewResponse() {}

    public ReviewResponse(String id, String userName, String userImageUrl,
                          String reviewText, String date, int rating) {
        this.id = id;
        this.userName = userName;
        this.userImageUrl = userImageUrl;
        this.reviewText = reviewText;
        this.date = date;
        this.rating = rating;
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getUserName() { return userName; }
    public void setUserName(String userName) { this.userName = userName; }

    public String getUserImageUrl() { return userImageUrl; }
    public void setUserImageUrl(String userImageUrl) { this.userImageUrl = userImageUrl; }

    public String getReviewText() { return reviewText; }
    public void setReviewText(String reviewText) { this.reviewText = reviewText; }

    public String getDate() { return date; }
    public void setDate(String date) { this.date = date; }

    public int getRating() { return rating; }
    public void setRating(int rating) { this.rating = rating; }
}
