from fastapi import FastAPI, Depends, HTTPException
from supabase import create_client, Client
from app.database import get_supabase

app = FastAPI(title="My FastAPI Supabase App")

# A simple health check endpoint
@app.get("/")
async def root():
    return {"message": "Hello World from FastAPI & Docker!"}

# Example endpoint that uses Supabase
@app.get("/users")
async def get_users(supabase: Client = Depends(get_supabase)):
    try:
        # Example: Fetch data from a 'users' table
        response = supabase.table('users').select("*").execute()
        return response.data
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))