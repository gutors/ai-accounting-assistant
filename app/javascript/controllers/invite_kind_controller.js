import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "kind" ]

  connect() {
    this.route()
  }

  route() {
    this.element.action = this.kindTarget.value === "Submitter" ? "/submitter_invites" : "/coordinator_invites"
  }
}
