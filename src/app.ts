import express from "express"
import cors from "cors"
import helmet from "helmet"
import dotenv from "dotenv"

dotenv.config()

const app = express()
const PORT = process.env.PORT || 3000

// Middleware
app.use(helmet())
app.use(cors())
app.use(express.json())

// Routes
// TODO: Add your /identify route here

app.listen(PORT, () => {
	console.log(`Server running on port ${PORT}`)
})
