function browseFolderPaths() {
    window.webkit.messageHandlers.guiproxy.postMessage('selectFolder');
}

function setupButtons() {
    $( "<button type='button' class='btn btn-sm btn-default' style='margin-left:20px; height:20px' onClick='window.stExtension.browseFolderPaths()'><span class='fa fa-ellipsis-h'></span>&nbsp;<span translate='' class='ng-scope'></span></button>" ).insertAfter( $("label[for='folderPath']") )
}

function setFolderPath(folderPath, folderLabel) {
    // Only set the Label if it was empty or the same as the end of the current path.
    if (($("#folderLabel").val() == "") || $("#folderPath").val().endsWith($("#folderLabel").val()) ) {
        $("#folderLabel").val(folderLabel);
    }
    $("#folderPath").val(folderPath);
}


window.stExtension = {
    browseFolderPaths: browseFolderPaths,
    setupButtons: setupButtons,
    setFolderPath: setFolderPath
};

