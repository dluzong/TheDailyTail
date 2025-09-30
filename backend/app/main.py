from fastapi import FastAPI, Depends, HTTPException
from supabase import create_client, Client
from app.database import get_supabase_client

app = FastAPI(title="The Daily Tail Backend")

# A simple health check endpoint
@app.get("/")
async def root():
    return {"message": "Hello World from The Daily Tail!"}

@app.get("/users")
async def get_users(supabase: Client = Depends(get_supabase_client)):
    try:
        # Example: Fetch data from a 'users' table
        response = supabase.table('users').select("*").execute()
        return response.data
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    
@app.get("/pets")
async def get_pets(supabase: Client = Depends(get_supabase_client)):
    try:
        response = supabase.table('pets').select("*").execute()
        return {"pets": response.data}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))