VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "ECPTextStream"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
'#
'////////////////////////////////////////////////////////////////////////////////////////////
' Copyright � 2021 W. Garc�a
' GPL-3.0 license | https://www.gnu.org/licenses/gpl-3.0.html/
' https://ingwilfredogarcia.wordpress.com
'#
'////////////////////////////////////////////////////////////////////////////////////////////
' GENERAL INFO:
' ECPTextStream is an easy-to-use class module developed to enable I/O operations over "big"
' text files, at high speed, from VBA. The module hasn�t reference to any external API library.
'////////////////////////////////////////////////////////////////////////////////////////////
'#
Option Explicit
'#
'////////////////////////////////////////////////////////////////////////////////////////////
' CONSTANTS:
Private Const SizeFactor As Long = 524288
'////////////////////////////////////////////////////////////////////////////////////////////
'#
'////////////////////////////////////////////////////////////////////////////////////////////
' PROPERTIES VARIABLES:
Private P_ATENDOFSTREAM As Boolean '---------------Indicates if the file's end is reached.
Private P_BUFFERLENGTH As Long '-------------------Number of chars in buffer.
Private P_BUFFERSIZE As Single '-------------------Buffer's size in MB (0.5 by default).
Private P_ENDSTREAMONLINEBREAK As Boolean '--------If true, each stream ends on a line break.
Private P_ISOPENSTREAM As Boolean '----------------Indicates if the object is linked to a file
Private P_LINEBREAK As String '--------------------Holds the char used to end a Stream.
Private P_STREAMLENGTH As Long '-------------------File len.
Private P_TEXT As String '-------------------------Holds the current stream's text.
'////////////////////////////////////////////////////////////////////////////////////////////
'#
'////////////////////////////////////////////////////////////////////////////////////////////
' VARIABLES:
' @Common
'////////////////////////////////////////////////////////////////////////////////////////////
'#
Private Buffer As String
Private BufferDelta As Long
Private BufferMark As Long
Private CorrectedPos As Long
Private EndLineMark As EndLineChar
Private FileHandled As Integer
Private InitialPos As Long
Private LCS As Long
Private NullChar As String
Private NullCharPos As Long
'////////////////////////////////////////////////////////////////////////////////////////////
'#
'////////////////////////////////////////////////////////////////////////////////////////////
' ENUMERATIONS:
Public Enum EndLineChar
    CRLF = 0
    CR = 1
    LF = 2
End Enum
'////////////////////////////////////////////////////////////////////////////////////////////
'#
' PROPERTIES:
Public Property Get atEndOfStream() As Boolean
Attribute atEndOfStream.VB_Description = "Gets the pointer�s overall status over the text stream."
    atEndOfStream = P_ATENDOFSTREAM
End Property
Public Property Get bufferLength() As Long
Attribute bufferLength.VB_Description = "Gets the number of string characters in the buffer."
    bufferLength = P_BUFFERLENGTH
End Property
Public Property Get bufferSize() As Single
Attribute bufferSize.VB_Description = "Gets or sets the buffer�s size, in MB, for text stream operations."
    bufferSize = P_BUFFERSIZE
End Property
Public Property Let bufferSize(value As Single)
    P_BUFFERSIZE = value
    P_BUFFERLENGTH = CLng(P_BUFFERSIZE * SizeFactor)
    Buffer = SPACE$(P_BUFFERLENGTH)
End Property
Public Property Get bufferString() As String
Attribute bufferString.VB_Description = "Gets the text data stored in the buffer."
    bufferString = P_TEXT
End Property
Public Property Get endStreamOnLineBreak() As Boolean
Attribute endStreamOnLineBreak.VB_Description = "Allows to end buffer just after the first, from right to left, line break character."
    endStreamOnLineBreak = P_ENDSTREAMONLINEBREAK
End Property
Public Property Let endStreamOnLineBreak(value As Boolean)
    P_ENDSTREAMONLINEBREAK = value
End Property
Public Property Get isOpenStream() As Boolean
    isOpenStream = P_ISOPENSTREAM
End Property
Public Property Get LineBreak() As String
Attribute LineBreak.VB_Description = "Returns the character used to end the last received stream. The value is vbNullString when the last stream is not forced to end on line break."
    LineBreak = P_LINEBREAK
End Property
Public Property Get pointerPosition() As Long
Attribute pointerPosition.VB_Description = "Gets the overall pointer position over the current text file."
    If P_ISOPENSTREAM Then
        pointerPosition = Seek(FileHandled)
    Else
        pointerPosition = 0
    End If
End Property
Public Property Get streamLength() As Long
Attribute streamLength.VB_Description = "Gets the current opened file�s size, in Bytes."
    streamLength = P_STREAMLENGTH
End Property
'////////////////////////////////////////////////////////////////////////////////////////////
'#
'////////////////////////////////////////////////////////////////////////////////////////////
' METHODS:
Public Sub CloseStream()
Attribute CloseStream.VB_Description = "Closes the current text file stream."
    If P_ISOPENSTREAM Then
        Close #FileHandled
        P_ISOPENSTREAM = False
    End If
End Sub
Private Sub FindEOLcharacter()
    Dim LastCrLfPos As Long
    Dim LastCrPos As Long
    Dim LastLfPos As Long
    Dim tmpResultPos As Long
    Dim bufferReverse As String
    Dim EOLchr As EndLineChar
    Dim missingEOLchar As Boolean
    Dim EOStream As Boolean
    Dim tmpBuffer As String

    Do
        bufferReverse = StrReverse(Buffer)
        LastCrLfPos = InStrB(1, bufferReverse, vbCrLf)
        LastCrPos = InStrB(1, bufferReverse, vbCr)
        LastLfPos = InStrB(1, bufferReverse, vbLf)
        missingEOLchar = (LastCrLfPos = 0 And LastCrPos = 0 And LastLfPos = 0)
        If missingEOLchar Then
            tmpBuffer = Buffer
            Get #FileHandled, , Buffer
            Buffer = tmpBuffer + Buffer
            InitialPos = Seek(FileHandled)
            BufferMark = LenB(Buffer)
            EOStream = ((P_STREAMLENGTH - InitialPos) <= 0)
            If EOStream Then
                NullCharPos = InStrB(Buffer, NullChar)
                If NullCharPos Then
                    Buffer = MidB$(Buffer, 1, NullCharPos)
                End If
            End If
        End If
    Loop While missingEOLchar And Not EOStream
    P_ATENDOFSTREAM = EOStream
    If Not EOStream Then
        tmpResultPos = LastCrLfPos
        EOLchr = CRLF
        If tmpResultPos < LastCrPos Then
            tmpResultPos = LastCrPos
            EOLchr = CR
        End If
        If tmpResultPos < LastLfPos Then
            tmpResultPos = LastLfPos
            EOLchr = LF
        End If
        Select Case EOLchr
            Case 0
                BufferDelta = tmpResultPos - 3
                P_LINEBREAK = vbCrLf
            Case Else
                BufferDelta = tmpResultPos - 1
                If EOLchr = 1 Then
                    P_LINEBREAK = vbCr
                Else
                    P_LINEBREAK = vbLf
                End If
        End Select
        BufferMark = BufferMark - BufferDelta
        CorrectedPos = InitialPos - (BufferDelta / 2)
    Else
        CorrectedPos = InitialPos
    End If
    Seek #FileHandled, CorrectedPos
End Sub
Public Sub OpenStream(filePath As String)
Attribute OpenStream.VB_Description = "Opens a stream over a text file."
    FileHandled = FreeFile
    Open filePath For Binary As #FileHandled
    P_ISOPENSTREAM = True
    P_STREAMLENGTH = LOF(FileHandled)
    StartVariables
End Sub
Public Sub ReadText()
Attribute ReadText.VB_Description = "Reads a number of characters from the stream file and saves the result to the current instance."
    If Not P_ATENDOFSTREAM And P_ISOPENSTREAM Then
        Select Case P_BUFFERLENGTH
            Case Is < LCS
                BufferDelta = 0
                Get #FileHandled, , Buffer
                InitialPos = Seek(FileHandled)
                BufferMark = LenB(Buffer)
                If P_ENDSTREAMONLINEBREAK Then
                    FindEOLcharacter
                    LCS = P_STREAMLENGTH - CorrectedPos
                    P_TEXT = MidB$(Buffer, 1, BufferMark)
                Else
                    P_LINEBREAK = vbNullString
                    LCS = P_STREAMLENGTH - InitialPos
                    P_ATENDOFSTREAM = False
                    P_TEXT = Buffer
                End If
            Case Else
                Buffer = SPACE$(LCS + 1)
                Get #FileHandled, , Buffer
                NullCharPos = InStrB(Buffer, NullChar)
                If NullCharPos Then
                    Buffer = MidB$(Buffer, 1, NullCharPos)
                End If
                P_ATENDOFSTREAM = True
                P_TEXT = Buffer
        End Select
    End If
End Sub
Public Sub RestartPointer()
Attribute RestartPointer.VB_Description = "Moves the pointer to the text stream�s beginning position."
    If P_ISOPENSTREAM Then
        Seek #FileHandled, 1
        StartVariables
    End If
End Sub
Public Sub SeekPointer(Position As Long)
Attribute SeekPointer.VB_Description = "Moves the pointer, over the target file, to the specified position."
    If Position > 0 Then
        If P_ISOPENSTREAM Then
            If P_STREAMLENGTH > 0 Then
                Seek #FileHandled, Position
                CorrectedPos = Seek(FileHandled)
                LCS = P_STREAMLENGTH - CorrectedPos
                P_ATENDOFSTREAM = (P_STREAMLENGTH < CorrectedPos)
            End If
        End If
    End If
End Sub
Private Sub StartVariables()
    CorrectedPos = 0
    P_BUFFERLENGTH = CLng(P_BUFFERSIZE * SizeFactor)
    Buffer = SPACE$(P_BUFFERLENGTH)
    LCS = P_STREAMLENGTH
    P_ATENDOFSTREAM = False
End Sub
Public Sub WriteBlankLines(Lines As Long, Optional EndLineMark As EndLineChar = 0)
Attribute WriteBlankLines.VB_Description = "Inserts a specified number of blank lines into the current opened text file."
    If P_ISOPENSTREAM Then
        Dim Idx As Long
        Select Case EndLineMark
            Case 0
                For Idx = 1 To Lines
                    Put #FileHandled, , vbCrLf
                Next Idx
            Case 1
                For Idx = 1 To Lines
                    Put #FileHandled, , vbCr
                Next Idx
            Case 2
                For Idx = 1 To Lines
                    Put #FileHandled, , vbLf
                Next Idx
        End Select
        P_STREAMLENGTH = LOF(FileHandled)
    End If
End Sub
Public Sub WriteText(ByRef TextData As String)
Attribute WriteText.VB_Description = "Writes the given string to the current opened text file."
    If P_ISOPENSTREAM Then
        Put #FileHandled, , TextData
        P_STREAMLENGTH = LOF(FileHandled)
    End If
End Sub
'////////////////////////////////////////////////////////////////////////////////////////////
Private Sub Class_Initialize()
    P_BUFFERSIZE = 0.5
    P_BUFFERLENGTH = CLng(P_BUFFERSIZE * SizeFactor)
    P_ENDSTREAMONLINEBREAK = False
    Buffer = SPACE$(P_BUFFERLENGTH)
    NullChar = ChrW(0)
End Sub
Private Sub Class_Terminate()
    If P_ISOPENSTREAM Then
        CloseStream
    End If
End Sub
