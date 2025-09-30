# TheDailyTail
Fall '25 Capstone Project

## How to Run Docker
docker build -t fastapi-backend .

docker run -it --rm -p 8000:8000 \
	-e SUPABASE_URL="https://your-project.supabase.co" \
	-e SUPABASE_KEY="your-service-role-key" \
	fastapi-backend

if you have .env
docker run -p 8000:8000 --env-file .env fastapi-backend

(see supabase proj for URL and KEY)
