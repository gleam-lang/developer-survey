export function getEventTargetValue(event) {
  return event.target.value || "";
}

export function getEventTargetChecked(event) {
  return event.target.checked || false;
}

export function preventDefault(event) {
  event.preventDefault();
}

export function getEventKey(event) {
  return event.key || "";
}
