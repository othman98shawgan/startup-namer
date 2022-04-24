# startup-namer
Q1:
  snappingSheetController Widget is the class thats used to impelemt the controller pattern in this library.
  It allows the develover to control a few features like:
  1. snapToPosition: Snaps to a given snapping position.
  2. stopCurrentSnapping : Stops the current snapping if there is one ongoing.
  3. setSnappingSheetPosition: Sets the position of the snapping sheet directly without any animation 
  4. currentPosition: Getting the current position of the sheet.
  5. currentSnappingPosition: Getting the current snapping position of the sheet.
  6. currentlySnapping: Returns true if the snapping sheet is currently trying to snap to a position.
  7. isAttached: Returns if a state is attached to this controller.



Q2:
  Snpping_sheet library uses the snapPostions property to control the various positions that the sheet can snap to, 
  the property contains a list of all of the positions the sheet below can snap to.

Q3:
  InkWell and GestureDetector have many common features, but the main difference is that GestureDetector provides you with more controls like dragging, 
  and the InkWell has ripple effect tap unlike GestureDetector. So you’ll have to use either of them based on your needs.
