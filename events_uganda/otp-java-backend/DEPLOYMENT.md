# Render.com Deployment Guide

This guide will help you deploy the Events Uganda OTP Backend to Render.com.

## Prerequisites

1. **GitHub Account** - Your code must be pushed to GitHub
2. **Render.com Account** - Create a free account at [render.com](https://render.com)
3. **PostgreSQL Database** - Will be created on Render

## Step 1: Push Code to GitHub

```bash
git add .
git commit -m "Ready for Render deployment"
git push origin main
```

## Step 2: Create PostgreSQL Database on Render

1. Log in to [Render.com](https://dashboard.render.com)
2. Click **"New +"** → **"PostgreSQL"**
3. Choose a region (select closest to your users)
4. Select **Free** tier or paid plan
5. Name: `eventsuganda-db`
6. Click **"Create Database"**
7. Wait for database to be created
8. Copy the **Internal Database URL** (save this for later)

## Step 3: Deploy Backend to Render

1. In Render dashboard, click **"New +"** → **"Web Service"**
2. Click **"Connect GitHub"** and authorize
3. Select your repository
4. Select the `otp-java-backend` folder (or root if it's in a separate repo)
5. Configure the following:

### Build Settings
- **Name**: `eventsuganda-backend`
- **Region**: Same as your database
- **Branch**: `main`
- **Runtime**: `Docker` (or leave default for auto-detection)
- **Build Command**: `./mvnw.cmd clean package -DskipTests`
- **Start Command**: `java -jar target/otp-backend-1.0.0.jar`

### Environment Variables
Add these environment variables:

| Key | Value | Description |
|-----|-------|-------------|
| `DATABASE_HOST` | Your database host | From Render database settings (e.g., `dpg-...a.oregon-postgres.render.com`) |
| `DATABASE_PORT` | `5432` | Database port (default: 5432) |
| `DATABASE_NAME` | Your database name | From Render database settings |
| `DATABASE_USERNAME` | Your database username | From Render database settings |
| `DATABASE_PASSWORD` | Your database password | From Render database settings |
| `JWT_SECRET` | A secret key (min 32 characters) | Used for JWT token signing (e.g., `EventsUganda2026SuperSecretKeyForJWTSigning!!`) |
| `SPRING_PROFILES_ACTIVE` | `prod` | Use production profile |

**Note**: Do NOT use `DATABASE_URL` (Render provides it in `postgres://` format, which is not compatible with JDBC). Instead, use the individual host/port/name/user/password env vars listed above.

**Note**: Get the database credentials from your PostgreSQL database page on Render.

6. Click **"Create Web Service"**
7. Wait for the build to complete (5-10 minutes)

## Step 4: Verify Deployment

1. Once deployed, Render will provide a URL like: `https://eventsuganda-backend.onrender.com`
2. Test the API endpoints:
   - Health check: `https://your-app.onrender.com/api/auth/register` (POST)
   - Login: `https://your-app.onrender.com/api/auth/login` (POST)

## Step 5: Update Flutter App

Update your Flutter app's `AuthService.java` to use the new Render URL:

```dart
static const String _baseUrl = 'https://your-app.onrender.com/api/auth';
```

## Troubleshooting

### Build Fails
- Check the build logs in Render dashboard
- Ensure `Procfile` exists in the root
- Verify `pom.xml` is correct

### Database Connection Issues
- Verify environment variables are set correctly (use `DATABASE_HOST`, `DATABASE_PORT`, `DATABASE_NAME`, `DATABASE_USERNAME`, `DATABASE_PASSWORD` - NOT `DATABASE_URL`)
- Check database is in the same region as the web service
- Ensure database is not in "Suspended" state
- **"Driver claims to not accept jdbcUrl"**: This error means Render's `postgres://` URL format was used directly as a JDBC URL. Fix by using the individual env vars (`DATABASE_HOST`, `DATABASE_PORT`, etc.) instead of `DATABASE_URL`.

### Application Won't Start
- Check logs for Java errors
- Verify the JAR file name matches in Procfile
- Ensure all dependencies are in `pom.xml`

## Free Tier Limitations

- **Web Service**: Free tier spins down after 15 minutes of inactivity (cold start ~30s)
- **Database**: 90 days free, then $7/month
- **Bandwidth**: 100GB/month free

## Paid Plans

For production use, consider:
- **Starter Web Service**: $7/month (no cold starts)
- **Production Database**: $7/month
- **More resources**: Higher tiers available

## Security Notes

- Never commit sensitive data to GitHub
- Use Render's environment variables for secrets
- Enable SSL (Render provides this automatically)
- Consider adding API authentication if needed

## Monitoring

- Render provides logs in the dashboard
- Set up alerts for failures
- Monitor database usage

## Support

- Render docs: [docs.render.com](https://docs.render.com)
- Spring Boot docs: [spring.io/guides](https://spring.io/guides)
