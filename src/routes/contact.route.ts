import { Router } from "express"
import * as identifyController from "../controllers/contact.controller"

const router = Router()

router.post("/identify", identifyController.identifyContact)

export default router
