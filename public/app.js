$(document).ready(function () {
  $("i.icon-remove").on("click", function () {
    var id = $(this).data("id");
    $.ajax({
      url:  "/" + id,
      type: "POST",
      data: { _method: "DELETE" },
      success: function () {
        $("#exception-" + id).hide();
      }
    });
  });
});
