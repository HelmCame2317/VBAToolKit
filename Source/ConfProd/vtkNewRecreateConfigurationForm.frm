VERSION 5.00
Begin {C62A69F0-16DC-11CE-9E98-00AA00574A4F} vtkNewRecreateConfigurationForm 
   Caption         =   "VBAToolKit - Recreate Configuration"
   ClientHeight    =   6510
   ClientLeft      =   45
   ClientTop       =   435
   ClientWidth     =   9045
   OleObjectBlob   =   "vtkNewRecreateConfigurationForm.frx":0000
   StartUpPosition =   1  'CenterOwner
End
Attribute VB_Name = "vtkNewRecreateConfigurationForm"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
'---------------------------------------------------------------------------------------
' Module    : vtkNewRecreateConfigurationForm
' Author    : Lucas Vitorino
' Purpose   : UserForm for VBAToolKit Recreate Configuration feature
'
' Copyright 2013 Skwal-Soft (http://skwalsoft.com)
'
'   Licensed under the Apache License, Version 2.0 (the "License");
'   you may not use this file except in compliance with the License.
'   You may obtain a copy of the License at
'
'       http://www.apache.org/licenses/LICENSE-2.0
'
'   Unless required by applicable law or agreed to in writing, software
'   distributed under the License is distributed on an "AS IS" BASIS,
'   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
'   See the License for the specific language governing permissions and
'   limitations under the License.
'---------------------------------------------------------------------------------------

Option Explicit

Private Const colorOK As Long = &HC000&
Private Const colorKO As Long = &HFF&
Private Const colorKOIntermediate As Long = &H80FF&

Private fso As New FileSystemObject
Private currentProjectName As String
Private currentConfigurationName As String
Private currentCM As New vtkConfigurationManager



'---------------------------------------------------------------------------------------
' Procedure : UserForm_Initialize
' Author    : Lucas Vitorino
' Purpose   : Initialize the different objects and variables in the form
'---------------------------------------------------------------------------------------
'
Private Sub UserForm_Initialize()

    On Error GoTo UserForm_Initialize_Error

    ' Display the path of the list of projects and set its color according to the validity
    ListOfProjectsTextBox.Text = xmlRememberedProjectsFullPath
    
    Dim dummyDom As New MSXML2.DOMDocument
    If Not fso.FileExists(xmlRememberedProjectsFullPath) Then
        ' File does not exist
        ListOfProjectsTextBox.ForeColor = colorKO
    ElseIf Not dummyDom.Load(xmlRememberedProjectsFullPath) Then
        ' File is not valid
        ListOfProjectsTextBox.ForeColor = colorKOIntermediate
    Else
        ' Everything is fine
        ListOfProjectsTextBox.ForeColor = colorOK
           
        Dim tmpProj As New vtkProject
        For Each tmpProj In listOfRememberedProjects
            ListOfProjectsComboBox.AddItem tmpProj.projectName
        Next
    
    End If

    ' Enable/Disable the browse buttons
    enableBrowseButtons

    On Error GoTo 0
    Exit Sub

UserForm_Initialize_Error:
    Err.Source = "vtkNewRecreateConfigurationForm::UserForm_Initialize"
    Debug.Print "Error " & Err.Number & " : " & Err.Description & " in " & Err.Source ' TMP
    Exit Sub

End Sub

'---------------------------------------------------------------------------------------
' Procedure : ListOfProjectsComboBox_Change
' Author    : Lucas Vitorino
' Purpose   : Manage what happens when a project is selected in the combobox :
'               - set fields
'               - reset relevant fields
'---------------------------------------------------------------------------------------
'
Private Sub ListOfProjectsComboBox_Change()

    On Error GoTo ListOfProjectsComboBox_Change_Error

    currentProjectName = ListOfProjectsComboBox.Value
    
    ' Clear all the comboboxes and textboxes about the configuration
    ConfigurationComboBox.Clear
    ConfigurationRelPathTextBox.Text = ""
    ConfigurationTemplatePathTextBox.Text = ""
    
    ' Set the root folder
    ProjectFolderPathTextBox.Text = vtkRootPathForProject(currentProjectName)
    If fso.folderExists(vtkRootPathForProject(currentProjectName)) Then
        ProjectFolderPathTextBox.ForeColor = colorOK
    Else
        ProjectFolderPathTextBox.ForeColor = colorKO
    End If
    
    ' Set the XML rel path
    ProjectXMLRelPathTextBox.Text = vtkXmlRelPathForProject(currentProjectName)
    
    Dim dummyDom As New MSXML2.DOMDocument
    If Not fso.FileExists(fso.BuildPath(vtkRootPathForProject(currentProjectName), vtkXmlRelPathForProject(currentProjectName))) Then
        ' File does not exist
        ProjectXMLRelPathTextBox.ForeColor = colorKO
    ElseIf Not dummyDom.Load(fso.BuildPath(vtkRootPathForProject(currentProjectName), vtkXmlRelPathForProject(currentProjectName))) Then
        ' File is not valid
        ProjectXMLRelPathTextBox.ForeColor = colorKOIntermediate
    Else
        ' Everything is fine
        ProjectXMLRelPathTextBox.ForeColor = colorOK
    End If
    
    ' Fill the configuration combobox
    Set currentCM = vtkConfigurationManagerForProject(currentProjectName)
    If Not currentCM Is Nothing Then
        Dim tmpConf As New vtkConfiguration
        For Each tmpConf In currentCM.configurations
            ConfigurationComboBox.AddItem tmpConf.name
        Next
    End If

    ' Enable/Disable the browse buttons
    enableBrowseButtons

    On Error GoTo 0
    Exit Sub

ListOfProjectsComboBox_Change_Error:
    Err.Source = "vtkNewRecreateConfigurationForm::ListOfProjectsComboBox_Change"
    
    Select Case Err.Number
        Case VTK_SHEET_NOT_VALID
            ' do nothing as we already know the xml file is not valid
        Case Else
            Debug.Print "Error " & Err.Number & " : " & Err.Description & " in " & Err.Source ' TMP
    End Select
    
    Exit Sub

End Sub

'---------------------------------------------------------------------------------------
' Procedure : ConfigurationComboBox_Change
' Author    : Lucas Vitorino
' Purpose   : Set fields and variables according to the configuration seleceted in the combobox.
'---------------------------------------------------------------------------------------
'
Private Sub ConfigurationComboBox_Change()
    
    On Error GoTo ConfigurationComboBox_Change_Error

    If Not currentCM Is Nothing Then
        currentConfigurationName = ConfigurationComboBox.Value
        ConfigurationRelPathTextBox.Text = currentCM.configurations(currentConfigurationName).path
        ConfigurationTemplatePathTextBox.Text = currentCM.configurations(currentConfigurationName).templatePath
        
        ' If there is a template
        If currentCM.configurations(currentConfigurationName).templatePath <> "" Then
            ' Show the text in red if the template is missing, in green if it is here
            If fso.FileExists(fso.BuildPath(vtkRootPathForProject(currentProjectName), currentCM.configurations(currentConfigurationName).templatePath)) Then
                ConfigurationTemplatePathTextBox.ForeColor = colorOK
            Else
                ConfigurationTemplatePathTextBox.ForeColor = colorKO
                CreateConfigurationButton.Enabled = False
                Exit Sub
            End If
        End If
        
        CreateConfigurationButton.Enabled = True
        
    End If
    
    ' Enable/Disable the browse buttons
    enableBrowseButtons

    On Error GoTo 0
    Exit Sub

ConfigurationComboBox_Change_Error:
    Err.Source = "vtkNewRecreateConfigurationForm::ConfigurationComboBox_Change"
    Debug.Print "Error " & Err.Number & " : " & Err.Description & " in " & Err.Source
    Exit Sub

    
End Sub


'---------------------------------------------------------------------------------------
' Procedure : CreateConfigurationButton_Click
' Author    : Lucas Vitorino
' Purpose   : Create the configuration.
'            TODO : no source files ?
'---------------------------------------------------------------------------------------
'
Private Sub CreateConfigurationButton_Click()
    On Error GoTo CreateConfigurationButton_Click_Error

    vtkRecreateConfiguration currentProjectName, currentConfigurationName

    MsgBox "Recreation successful !", vbOKOnly

    On Error GoTo 0
    Exit Sub

CreateConfigurationButton_Click_Error:
    Err.Source = "vtkNewRecreateConfigurationForm::CreateConfigurationButton_Click"
    MsgBox "Recreation failed : Error " & Err.Number & " : " & Err.Description & " in " & Err.Source, vbOKOnly
    Exit Sub

End Sub


'---------------------------------------------------------------------------------------
' Procedure : enableBrowseButtons
' Author    : Lucas Vitorino
' Purpose   : Manage the "enabled" property of the different "browse" buttons.
'             Typically, a button must be disabled when there is no text in the field it corresponds to.
'---------------------------------------------------------------------------------------
'
Private Sub enableBrowseButtons()

    On Error GoTo enableBrowseButtons_Error
    
    ' List of projects
    ListOfProjectsBrowseButton.Enabled = (ListOfProjectsTextBox.Text <> "")
    
    ' Project folder
    ProjectFolderPathBrowseButton.Enabled = (ProjectFolderPathTextBox.Text <> "")
    
    ' Project XML relative path
    ProjectXMLRelPathBrowseButton.Enabled = (ProjectXMLRelPathTextBox.Text <> "")
    
    ' Template path
    ConfigurationTemplatePathBrowseButton.Enabled = (ConfigurationTemplatePathTextBox.Text <> "")

    On Error GoTo 0
    Exit Sub

enableBrowseButtons_Error:
    Err.Source = "vtkNewRecreateConfigurationForm::enableBrowseButtons"
    Debug.Print "Error " & Err.Number & " : " & Err.Description & " in " & Err.Source
    Exit Sub

End Sub


'---------------------------------------------------------------------------------------
' Procedure : ListOfProjectsBrowseButton_Click
' Author    : Lucas Vitorino
' Purpose   : Allows the choice of the path of the file containig the list of projects.
'---------------------------------------------------------------------------------------
'
Private Sub ListOfProjectsBrowseButton_Click()
    
    ' Show the window
    With Application.FileDialog(msoFileDialogFilePicker)
        .AllowMultiSelect = False
        .Show
        If .SelectedItems.Count > 0 Then
            xmlRememberedProjectsFullPath = .SelectedItems(1)
        End If
    End With
    
    ' Re initialize the form
    UserForm_Initialize
    
End Sub
