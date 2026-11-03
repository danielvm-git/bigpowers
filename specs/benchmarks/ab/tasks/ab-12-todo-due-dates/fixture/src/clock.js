// Today's date as YYYY-MM-DD. Tests pin it with TODO_TODAY; never read the date any other way.
export function today() {
  return process.env.TODO_TODAY || new Date().toISOString().slice(0, 10);
}
