import axios from "axios";
import { useEffect } from "react";

const apiUrl = import.meta.env.VITE_API_URL;

function HomePage() {
  useEffect(()=> {
    const fetchBackend =  async () => {
    try {
      const res = await axios.get(apiUrl)
      if (res) {
        console.log(res.data)
      }
    }
    catch (err) {
      console.log(err)
    }
    }
    fetchBackend()
    
  },[])

  return (
    <div>
      <h1>Home</h1>
    </div>
  );
}

export default HomePage;