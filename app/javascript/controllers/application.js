import { Application } from "@hotwired/stimulus"
import Sortable from "sortablejs"

const application = Application.start()

// Configure Stimulus development experience
application.debug = false
window.Stimulus   = application

export { application }
