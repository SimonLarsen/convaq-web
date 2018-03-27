function forceUpdateSelected(table) {
  var selected = table.rows(".selected").indexes().toArray();
  Shiny.onInputChange("resultsTable_rows_selected", selected);
}
function selectAllRows() {
  var table = $("#resultsTable .dataTables_scrollBody table").DataTable();
  table.rows().nodes().to$().addClass("selected");
  forceUpdateSelected(table);
}
function deselectAllRows() {
  var table = $("#resultsTable .dataTables_scrollBody table").DataTable();
  table.rows(".selected").nodes().to$().removeClass("selected");
  forceUpdateSelected(table);
}

$(function() {
  $("#selectAllRowsButton").on("click", selectAllRows);
  $("#deselectAllRowsButton").on("click", deselectAllRows);
});