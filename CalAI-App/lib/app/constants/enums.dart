enum QueryStatus {
  SUCCESS,
  FAILED,
}

enum ProcessingStatus {
  PROCESSING,
  COMPLETED,
  FAILED,
}

enum EntrySource {
  SCANNER,        // Added via camera/gallery scan
  FOOD_DATABASE,  // Added from food database
  MANUAL_ENTRY,   // Added manually
  EXERCISE,       // Exercise entry
}