import express from "express"
import cors from "cors"
import helmet from "helmet"
import dotenv from "dotenv"
import contactRoutes from "./routes/contact.route"

dotenv.config()

const app = express()
const PORT = process.env.PORT || 3000

// Middleware
app.use(helmet())
app.use(cors())
app.use(express.json())

//Routess
app.use("/", contactRoutes)

app.listen(PORT, () => {
	console.log(`Server running on port ${PORT}`)
})
