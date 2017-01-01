VERSION 5.00
Begin VB.Form FormChannelMixer 
   BackColor       =   &H80000005&
   BorderStyle     =   4  'Fixed ToolWindow
   Caption         =   "Channel mixer"
   ClientHeight    =   7845
   ClientLeft      =   45
   ClientTop       =   285
   ClientWidth     =   12150
   BeginProperty Font 
      Name            =   "Tahoma"
      Size            =   8.25
      Charset         =   0
      Weight          =   400
      Underline       =   0   'False
      Italic          =   0   'False
      Strikethrough   =   0   'False
   EndProperty
   LinkTopic       =   "Form1"
   MaxButton       =   0   'False
   MinButton       =   0   'False
   ScaleHeight     =   523
   ScaleMode       =   3  'Pixel
   ScaleWidth      =   810
   ShowInTaskbar   =   0   'False
   Begin PhotoDemon.pdFxPreviewCtl pdFxPreview 
      Height          =   6735
      Left            =   120
      TabIndex        =   1
      Top             =   120
      Width           =   5625
      _ExtentX        =   9922
      _ExtentY        =   11880
   End
   Begin PhotoDemon.pdSlider sltRed 
      Height          =   705
      Left            =   6120
      TabIndex        =   2
      Top             =   1800
      Width           =   5895
      _ExtentX        =   10398
      _ExtentY        =   1270
      Caption         =   "red"
      Min             =   -200
      Max             =   200
      SliderTrackStyle=   3
      GradientColorMiddle=   255
   End
   Begin PhotoDemon.pdSlider sltGreen 
      Height          =   705
      Left            =   6120
      TabIndex        =   3
      Top             =   2760
      Width           =   5895
      _ExtentX        =   10398
      _ExtentY        =   1270
      Caption         =   "green"
      Min             =   -200
      Max             =   200
      SliderTrackStyle=   3
      GradientColorMiddle=   65280
   End
   Begin PhotoDemon.pdSlider sltBlue 
      Height          =   705
      Left            =   6120
      TabIndex        =   4
      Top             =   3720
      Width           =   5895
      _ExtentX        =   10398
      _ExtentY        =   1270
      Caption         =   "blue"
      Min             =   -200
      Max             =   200
      SliderTrackStyle=   3
      GradientColorMiddle=   16711680
   End
   Begin PhotoDemon.pdCheckBox chkMonochrome 
      Height          =   375
      Left            =   6120
      TabIndex        =   5
      Top             =   6120
      Width           =   5760
      _ExtentX        =   10160
      _ExtentY        =   582
      Caption         =   "monochrome"
   End
   Begin PhotoDemon.pdSlider sltConstant 
      Height          =   705
      Left            =   6120
      TabIndex        =   6
      Top             =   4680
      Width           =   5895
      _ExtentX        =   10398
      _ExtentY        =   1270
      Caption         =   "constant"
      Min             =   -255
      Max             =   255
      SliderTrackStyle=   2
   End
   Begin PhotoDemon.pdCheckBox chkLuminance 
      Height          =   375
      Left            =   6120
      TabIndex        =   7
      Top             =   6480
      Width           =   5760
      _ExtentX        =   10160
      _ExtentY        =   582
      Caption         =   "preserve luminance"
   End
   Begin PhotoDemon.pdCommandBar cmdBar 
      Align           =   2  'Align Bottom
      Height          =   750
      Left            =   0
      TabIndex        =   0
      Top             =   7095
      Width           =   12150
      _ExtentX        =   21431
      _ExtentY        =   1323
   End
   Begin PhotoDemon.pdButtonStrip btsChannel 
      Height          =   960
      Left            =   6000
      TabIndex        =   8
      Top             =   120
      Width           =   6000
      _ExtentX        =   10583
      _ExtentY        =   1058
      Caption         =   "output channel"
   End
   Begin PhotoDemon.pdLabel lblTitle 
      Height          =   285
      Index           =   0
      Left            =   6000
      Top             =   1320
      Width           =   6015
      _ExtentX        =   10610
      _ExtentY        =   503
      Caption         =   "input channel(s)"
      FontSize        =   12
      ForeColor       =   4210752
   End
   Begin PhotoDemon.pdLabel lblTitle 
      Height          =   285
      Index           =   1
      Left            =   6000
      Top             =   5760
      Width           =   5820
      _ExtentX        =   10266
      _ExtentY        =   503
      Caption         =   "options for all channels"
      FontSize        =   12
      ForeColor       =   4210752
   End
End
Attribute VB_Name = "FormChannelMixer"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
'***************************************************************************
'Channel Mixer Form
'Copyright 2013-2017 by Audioglider and Tanner Helland
'Created: 08/June/13
'Last updated: 23/September/14
'Last update: rework the interface a bit; add a button strip, increase white space, improve title labels
'
'Many thanks to talented contributer Audioglider for creating this tool.
'
'Standard channel mixer dialog.  Layout and feature set derived from comparable tools in Photoshop and GIMP.
' Per convention, all channels can be modified simultaneously.  For convenience, a "constant" slider is also
' provided, allowing for simple uniform adjustments.
'
'A "monochrome" option is provided for outputting a grayscale image.  Monochrome values are stored separately, so
' any changes made while in monochrome mode will not overwrite existing color channel values.
'
'A "preserve luminance" option is provided for applying color changes without changing the overall composition
' of the photo.  This is disabled when "monochrome" is active (obviously, as otherwise the gray values would
' never change!)
'
'All source code in this file is licensed under a modified BSD license.  This means you may use the code in your own
' projects IF you provide attribution.  For more information, please visit http://photodemon.org/about/license/
'
'***************************************************************************

Option Explicit

Private Enum OutputChannel
    RedOutput = 0
    GreenOutput = 1
    BlueOutput = 2
    GrayOutput = 3
End Enum

Private Enum InputChannel
    RedInput = 0
    GreenInput = 1
    BlueInput = 2
    ConstantInput = 3
End Enum

#If False Then
    Private Const RedOutput = 0, GreenOutput = 1, BlueOutput = 2, GrayOutput = 3
    Private Const RedInput = 0, GreenInput = 1, BlueInput = 2, ConstantInput = 3
#End If

'Because all channels can be modified independently, we need to store the settings of each channel.
' First dim: output channel (red/green/blue/gray)
' Second dim: input channel (red/green/blue/constant value)
Private m_curSliderValues(0 To 3, 0 To 3) As Long

Private m_forbidUpdate As Boolean

Private Sub btsChannel_Click(ByVal buttonIndex As Long)

    'Populate the sliders with any previously saved values
    m_forbidUpdate = True
    sltRed.Value = m_curSliderValues(btsChannel.ListIndex, RedInput)
    sltGreen.Value = m_curSliderValues(btsChannel.ListIndex, GreenInput)
    sltBlue.Value = m_curSliderValues(btsChannel.ListIndex, BlueInput)
    sltConstant.Value = m_curSliderValues(btsChannel.ListIndex, ConstantInput)
    m_forbidUpdate = False
    
    UpdatePreview

End Sub

Private Sub chkLuminance_Click()
    UpdatePreview
End Sub

'To match GIMP's behavior (which is actually well-designed in this case), disable the output combo box
Private Sub chkMonochrome_Click()
    
    If CBool(chkMonochrome) Then
        
        chkLuminance.Enabled = False
        btsChannel.Enabled = False
        
        'Populate the sliders with any previously saved values
        m_forbidUpdate = True
        sltRed.Value = m_curSliderValues(GrayOutput, RedInput)
        sltGreen.Value = m_curSliderValues(GrayOutput, GreenInput)
        sltBlue.Value = m_curSliderValues(GrayOutput, BlueInput)
        sltConstant.Value = m_curSliderValues(GrayOutput, ConstantInput)
        m_forbidUpdate = False
                
    Else
    
        chkLuminance.Enabled = True
        btsChannel.Enabled = True
        
        'Populate the sliders with any previously saved values
        m_forbidUpdate = True
        sltRed.Value = m_curSliderValues(btsChannel.ListIndex, RedInput)
        sltGreen.Value = m_curSliderValues(btsChannel.ListIndex, GreenInput)
        sltBlue.Value = m_curSliderValues(btsChannel.ListIndex, BlueInput)
        sltConstant.Value = m_curSliderValues(btsChannel.ListIndex, ConstantInput)
        m_forbidUpdate = False
        
    End If
    
    UpdatePreview
    
End Sub

'Apply a new channel mixer to the image
' Inputs:
'  - all modifiers as one long string; see "createChannelParamString" for how this string is assembled
Public Sub ApplyChannelMixer(ByVal channelMixerParams As String, Optional ByVal toPreview As Boolean = False, Optional ByRef dstPic As pdFxPreviewCtl)
    
    If Not toPreview Then Message "Mixing color channels..."
    
    'Because this tool has so many parameters, they are condensed into a single string and passed here.  We need to
    ' parse out individual values before continuing.
    Dim cParams As pdParamString
    Set cParams = New pdParamString
    cParams.SetParamString channelMixerParams
    
    Dim channelModifiers(0 To 3, 0 To 3) As Double
    Dim x As Long, y As Long
    For x = 0 To 3
        For y = 0 To 3
            'The "constant" modifier is added to the final channel value as a whole number, but the other values are
            ' used as multiplication factors - so divide them by 100.
            If y = 3 Then
                channelModifiers(x, y) = cParams.GetLong((x * 4) + y + 1)
            Else
                channelModifiers(x, y) = CDblCustom(cParams.GetLong((x * 4) + y + 1)) / 100
            End If
        Next y
    Next x
    
    Dim isMonochrome As Boolean
    isMonochrome = cParams.GetBool(17)
    
    Dim preserveLuminance As Boolean
    preserveLuminance = cParams.GetBool(18)
        
    'Create a local array and point it at the pixel data we want to operate on
    Dim ImageData() As Byte
    Dim tmpSA As SAFEARRAY2D
    
    PrepImageData tmpSA, toPreview, dstPic
    CopyMemory ByVal VarPtrArray(ImageData()), VarPtr(tmpSA), 4
        
    'Local loop variables can be more efficiently cached by VB's compiler, so we transfer all relevant loop data here
    Dim initX As Long, initY As Long, finalX As Long, finalY As Long
    initX = curDIBValues.Left
    initY = curDIBValues.Top
    finalX = curDIBValues.Right
    finalY = curDIBValues.Bottom
            
    'These values will help us access locations in the array more quickly.
    ' (qvDepth is required because the image array may be 24 or 32 bits per pixel, and we want to handle both cases.)
    Dim QuickVal As Long, qvDepth As Long
    qvDepth = curDIBValues.BytesPerPixel
    
    'To keep processing quick, only update the progress bar when absolutely necessary.  This function calculates that value
    ' based on the size of the area to be processed.
    Dim progBarCheck As Long
    progBarCheck = FindBestProgBarValue()
    
    'Finally, a bunch of variables used in color calculation
    Dim r As Long, g As Long, b As Long
    Dim newR As Long, newG As Long, newB As Long, newGray As Long
    Dim h As Double, s As Double, l As Double
    Dim originalLuminance As Double
        
    'Apply the filter
    For x = initX To finalX
        QuickVal = x * qvDepth
    For y = initY To finalY
        
        r = ImageData(QuickVal + 2, y)
        g = ImageData(QuickVal + 1, y)
        b = ImageData(QuickVal, y)
        
        'Create a new value for each color based on the input parameters
        If isMonochrome Then
            newGray = r * channelModifiers(3, 0) + g * channelModifiers(3, 1) + b * channelModifiers(3, 2) + channelModifiers(3, 3)
            
            If newGray > 255 Then newGray = 255
            If newGray < 0 Then newGray = 0
            
            'Note: luminance preservation serves no purpose when monochrome is selected, so I do not process it here
            
            ImageData(QuickVal + 2, y) = newGray
            ImageData(QuickVal + 1, y) = newGray
            ImageData(QuickVal, y) = newGray
            
        Else
        
            'If luminance is being preserved, we need to determine the initial luminance value
            If preserveLuminance Then originalLuminance = (GetLuminance(r, g, b) / 255)
        
            newR = r * channelModifiers(0, 0) + g * channelModifiers(0, 1) + b * channelModifiers(0, 2) + channelModifiers(0, 3)
            newG = r * channelModifiers(1, 0) + g * channelModifiers(1, 1) + b * channelModifiers(1, 2) + channelModifiers(1, 3)
            newB = r * channelModifiers(2, 0) + g * channelModifiers(2, 1) + b * channelModifiers(2, 2) + channelModifiers(2, 3)
            
            'Fit everything in the [0, 255] range
            If newR > 255 Then newR = 255
            If newR < 0 Then newR = 0
            If newG > 255 Then newG = 255
            If newG < 0 Then newG = 0
            If newB > 255 Then newB = 255
            If newB < 0 Then newB = 0
            
            'If the user wants us to preserve luminance, determine the hue and saturation of the new color, then replace the luminance
            ' value with the original
            If preserveLuminance Then
                tRGBToHSL newR, newG, newB, h, s, l
                tHSLToRGB h, s, originalLuminance, newR, newG, newB
            End If
            
            ImageData(QuickVal + 2, y) = newR
            ImageData(QuickVal + 1, y) = newG
            ImageData(QuickVal, y) = newB
            
        End If
                
    Next y
        If (Not toPreview) Then
            If (x And progBarCheck) = 0 Then
                If UserPressedESC() Then Exit For
                SetProgBarVal x
            End If
        End If
    Next x
    
    'With our work complete, point ImageData() away from the DIB and deallocate it
    CopyMemory ByVal VarPtrArray(ImageData), 0&, 4
    Erase ImageData
    
    'Pass control to finalizeImageData, which will handle the rest of the rendering
    FinalizeImageData toPreview, dstPic
    
End Sub

Private Sub cmdBar_AddCustomPresetData()

    'Because this control encompasses a bunch of "invisible" settings, e.g. channel values for channels other
    ' than the selected one, we must write out the ENTIRE CHANNEL ARRAY to the preset file
    cmdBar.AddPresetData "channelArray", CreateChannelParamString

End Sub

'OK button
Private Sub cmdBar_OKClick()
    UpdateStoredValues
    Process "Channel mixer", , CreateChannelParamString(), UNDO_LAYER
End Sub

Private Sub cmdBar_RandomizeClick()
    
    'We actually want to randomize the entire stored value array, including channels that are not current visible
    Dim x As Long, y As Long
    For x = 0 To 3
        For y = 0 To 3
            If x < 3 Then
                m_curSliderValues(x, y) = -200 + Int(Rnd * 401)
            Else
                m_curSliderValues(x, y) = -255 + Int(Rnd * 511)
            End If
        Next y
    Next x
    
    UpdateStoredValues
    
End Sub

Private Sub cmdBar_ReadCustomPresetData()

    'Because this control encompasses a bunch of "invisible" settings, e.g. channel values for channels other
    ' than the selected one, we must read out a custom preset string that contains the ENTIRE CHANNEL ARRAY
    Dim tmpParamString As String
    tmpParamString = cmdBar.RetrievePresetData("channelArray")
    
    'We can now parse that string to retrieve the values for each individual channel
    Dim cParams As pdParamString
    Set cParams = New pdParamString
    cParams.SetParamString tmpParamString
    
    Dim x As Long, y As Long
    For x = 0 To 3
        For y = 0 To 3
            m_curSliderValues(x, y) = cParams.GetLong((x * 4) + y + 1)
        Next y
    Next x
    
    'Sync the on-screen controls with whatever slider values are relevant
    m_forbidUpdate = True
    If Not CBool(chkMonochrome) Then
        btsChannel.Enabled = True
        sltRed.Value = m_curSliderValues(btsChannel.ListIndex, RedInput)
        sltGreen.Value = m_curSliderValues(btsChannel.ListIndex, GreenInput)
        sltBlue.Value = m_curSliderValues(btsChannel.ListIndex, BlueInput)
        sltConstant.Value = m_curSliderValues(btsChannel.ListIndex, ConstantInput)
    Else
        btsChannel.Enabled = False
        sltRed.Value = m_curSliderValues(GrayOutput, RedInput)
        sltGreen.Value = m_curSliderValues(GrayOutput, GreenInput)
        sltBlue.Value = m_curSliderValues(GrayOutput, BlueInput)
        sltConstant.Value = m_curSliderValues(GrayOutput, ConstantInput)
    End If
    m_forbidUpdate = False

End Sub

Private Sub cmdBar_RequestPreviewUpdate()
    UpdateStoredValues
    UpdatePreview
End Sub

'RESET button
Private Sub cmdBar_ResetClick()

    'Fill the "stored value" array with default settings appropriate to each channel; basically, set each channel
    ' to their current value (e.g. red = "red 100%", "0%" for all other channels)
    Dim i As Long
    For i = 0 To 3
    
        Select Case i
        
            Case RedOutput
                m_curSliderValues(RedOutput, RedInput) = 100
                m_curSliderValues(RedOutput, GreenInput) = 0
                m_curSliderValues(RedOutput, BlueInput) = 0
                m_curSliderValues(RedOutput, ConstantInput) = 0
            
            Case GreenOutput
                m_curSliderValues(GreenOutput, RedInput) = 0
                m_curSliderValues(GreenOutput, GreenInput) = 100
                m_curSliderValues(GreenOutput, BlueInput) = 0
                m_curSliderValues(GreenOutput, ConstantInput) = 0
            
            Case BlueOutput
                m_curSliderValues(BlueOutput, RedInput) = 0
                m_curSliderValues(BlueOutput, GreenInput) = 0
                m_curSliderValues(BlueOutput, BlueInput) = 100
                m_curSliderValues(BlueOutput, ConstantInput) = 0
                
            'I'm not sure the best preset values to suggest for gray; for now, I'm defaulting to the ITU standard
            ' conversion formula - that should provide a good starting point for user modifications.
            Case GrayOutput
                m_curSliderValues(GrayOutput, RedInput) = 21
                m_curSliderValues(GrayOutput, GreenInput) = 72
                m_curSliderValues(GrayOutput, BlueInput) = 7
                m_curSliderValues(GrayOutput, ConstantInput) = 0
        
        End Select
    
    Next i
    
    'Reset the combo box and sliders on this page to default values
    btsChannel.ListIndex = 0
    sltRed.Value = 100
    sltGreen.Value = 0
    sltBlue.Value = 0
    sltConstant.Value = 0
    chkMonochrome.Value = vbUnchecked
    chkLuminance.Value = vbChecked
    
End Sub

Private Sub Form_Load()
    
    cmdBar.MarkPreviewStatus False
    
    'Per convention, monochrome mode is handled via a separate checkbox.  This is also an easier solution for us, as
    ' it's difficult to apply changes to an imaginary "gray channel" (we'd have to divvy up any "gray channel"
    ' changes to each of red, green, and blue, and without a consistent way to do that the results would be
    ' unpredictable - I'm fairly certain this is why Photoshop etc. provide a separate "monochrome" checkbox)
    
    'Populate the channel selector
    btsChannel.AddItem "red", 0
    btsChannel.AddItem "green", 1
    btsChannel.AddItem "blue", 2
    
    btsChannel.AssignImageToItem 0, "", Interface.GetRuntimeUIDIB(PDRUID_CHANNEL_RED, 16, 2)
    btsChannel.AssignImageToItem 1, "", Interface.GetRuntimeUIDIB(PDRUID_CHANNEL_GREEN, 16, 2)
    btsChannel.AssignImageToItem 2, "", Interface.GetRuntimeUIDIB(PDRUID_CHANNEL_BLUE, 16, 2)
    
    btsChannel.ListIndex = 0
            
    'Apply translations and visual themes
    ApplyThemeAndTranslations Me
    
    'If the last-used settings involve the monochrome check box, the luminance check box may not be deactivated properly
    ' (due to no Click event being fired).  Forcibly check this state in advance.
    chkLuminance.Enabled = Not CBool(chkMonochrome)
    
    'Display the previewed effect in the neighboring window
    cmdBar.MarkPreviewStatus True
    UpdatePreview
    
End Sub

Private Sub Form_Unload(Cancel As Integer)
    ReleaseFormTheming Me
End Sub

Private Sub sltBlue_Change()
    If Not m_forbidUpdate Then
        UpdateStoredValues
        UpdatePreview
    End If
End Sub

Private Sub sltBlue_ResetClick()
    If CBool(chkMonochrome) Then
        sltBlue.Value = 7
    Else
        If (btsChannel.ListIndex = BlueOutput) Then sltBlue.Value = 100 Else sltBlue.Value = 0
    End If
End Sub

Private Sub sltConstant_Change()
    If Not m_forbidUpdate Then
        UpdateStoredValues
        UpdatePreview
    End If
End Sub

Private Sub sltGreen_Change()
    If Not m_forbidUpdate Then
        UpdateStoredValues
        UpdatePreview
    End If
End Sub

Private Sub sltGreen_ResetClick()
    If CBool(chkMonochrome) Then
        sltGreen.Value = 72
    Else
        If (btsChannel.ListIndex = GreenOutput) Then sltGreen.Value = 100 Else sltGreen.Value = 0
    End If
End Sub

Private Sub sltRed_Change()
    If Not m_forbidUpdate Then
        UpdateStoredValues
        UpdatePreview
    End If
End Sub

Private Sub sltRed_ResetClick()
    If CBool(chkMonochrome) Then
        sltRed.Value = 21
    Else
        If (btsChannel.ListIndex = RedOutput) Then sltRed.Value = 100 Else sltRed.Value = 0
    End If
End Sub

Private Sub UpdatePreview()
    If cmdBar.PreviewsAllowed Then ApplyChannelMixer CreateChannelParamString(), True, pdFxPreview
End Sub

'Because the user can change multiple channels at once, we need to store all current channel values in memory.
Private Sub UpdateStoredValues()

    'Store values according to the current combo box or monochrome setting
    If CBool(chkMonochrome) Then
        m_curSliderValues(GrayOutput, RedInput) = sltRed.Value
        m_curSliderValues(GrayOutput, GreenInput) = sltGreen.Value
        m_curSliderValues(GrayOutput, BlueInput) = sltBlue.Value
        m_curSliderValues(GrayOutput, ConstantInput) = sltConstant.Value
    Else
        m_curSliderValues(btsChannel.ListIndex, RedInput) = sltRed.Value
        m_curSliderValues(btsChannel.ListIndex, GreenInput) = sltGreen.Value
        m_curSliderValues(btsChannel.ListIndex, BlueInput) = sltBlue.Value
        m_curSliderValues(btsChannel.ListIndex, ConstantInput) = sltConstant.Value
    End If

End Sub

'Because this tool has a complex set of input values, we need to condense them all into a single string.
' This function handles the creation of that string for both previews and full-image applications.
Private Function CreateChannelParamString() As String

    Dim paramString As String
    paramString = ""
    
    'Start by adding all channel input values to the string
    Dim i As Long, j As Long
    For i = 0 To 3
        For j = 0 To 3
            paramString = paramString & Trim$(Str(m_curSliderValues(i, j))) & "|"
        Next j
    Next i
    
    'Next, add the monochrome checkbox value
    paramString = paramString & Trim$(Str(CBool(chkMonochrome))) & "|"
    
    'Finally, add the preserve luminance checkbox value
    paramString = paramString & Trim$(Str(CBool(chkLuminance)))
    
    CreateChannelParamString = paramString

End Function

'If the user changes the position and/or zoom of the preview viewport, the entire preview must be redrawn.
Private Sub pdFxPreview_ViewportChanged()
    UpdatePreview
End Sub

