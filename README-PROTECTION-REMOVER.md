# Office Protection Remover

Automated Windows batch scripts to remove protection from Microsoft Office documents (Word, Excel, PowerPoint).

## Features

- ✅ **Automated processing** - No manual ZIP extraction needed
- ✅ **Safe backups** - Original files remain untouched
- ✅ **Comprehensive support** - Handles documents, workbooks, presentations, and templates
- ✅ **Intelligent error handling** - Clear messages for unsupported formats
- ✅ **No additional software** - Uses built-in Windows PowerShell

## Supported Formats

### Modern XML-Based Formats (Office 2007+)

| Application | Extensions Supported | Protection Types Removed |
|-------------|---------------------|-------------------------|
| **PowerPoint** | `.pptx`, `.pptm`, `.ppsx`, `.potx`, `.potm` | Presentation modification lock (`modifyVerifier`) |
| **Excel** | `.xlsx`, `.xlsm`, `.xltx`, `.xltm` | Workbook protection, worksheet protection, file sharing restrictions |
| **Word** | `.docx`, `.docm`, `.dotx`, `.dotm` | Document editing restrictions, write protection |

### Legacy Formats (Not Supported)

Binary formats from Office 97-2003 (`.ppt`, `.xls`, `.doc`, `.pps`, `.pot`, `.xlt`, `.dot`) are **NOT** supported because they use a different binary structure.

**To use legacy files:**
1. Open the file in Microsoft Office
2. Click "File" → "Save As"
3. Choose the modern equivalent (.pptx, .xlsx, .docx)
4. Run the script on the converted file

## Available Scripts

### 1. `remove-office-protection.bat` (Recommended)

Universal script that handles all Office formats automatically.

**Usage:**
```batch
# Drag and drop method
Just drag your file onto remove-office-protection.bat

# Command line method
remove-office-protection.bat "C:\path\to\document.docx"
remove-office-protection.bat "C:\path\to\spreadsheet.xlsx"
remove-office-protection.bat "C:\path\to\presentation.pptx"
```

### 2. `remove-pptx-protection.bat`

PowerPoint-only version (legacy, use universal script instead).

## What Each Script Does

### Step-by-Step Process

1. **Creates backup** - Makes a copy named `filename_backup.ext`
2. **Converts to ZIP** - Office files are actually ZIP archives
3. **Extracts contents** - Unpacks the internal XML structure
4. **Locates protection files** - Finds the relevant XML files
5. **Removes protection tags** - Deletes protection-related XML elements
6. **Repackages file** - Creates new ZIP archive
7. **Restores extension** - Renames back to original format
8. **Outputs result** - Creates `filename_unprotected.ext`

### Protection Tags Removed

**PowerPoint:**
```xml
<p:modifyVerifier cryptProviderType="..." />
```

**Excel:**
```xml
<workbookProtection workbookPassword="..." />
<sheetProtection password="..." />
<fileSharing reservationPassword="..." />
```

**Word:**
```xml
<w:documentProtection w:edit="..." />
<w:writeProtection w:cryptProviderType="..." />
```

## Output Files

After running the script, you'll have:

```
original-file.docx              ← Original (unchanged)
original-file_backup.docx       ← Backup copy
original-file_unprotected.docx  ← Protection removed ✨
```

## System Requirements

- **OS**: Windows 7 or later
- **PowerShell**: Version 3.0+ (included in Windows 8+)
- **Permissions**: No admin rights required

## Security & Safety

### What This Tool Does
- ✅ Removes editing restrictions from YOUR OWN files
- ✅ Helps recover documents when you forgot the password
- ✅ Legal for personal and business use on files you own

### What This Tool Doesn't Do
- ❌ Does NOT decrypt encrypted files
- ❌ Does NOT crack password-protected files
- ❌ Does NOT bypass DRM or copyright protection
- ❌ Does NOT work on files with strong encryption

### Legal Notice

This tool is intended for legitimate use only:
- Recovering YOUR OWN files when passwords are lost
- Removing restrictions from documents you created
- Editing templates with inadvertent protection

**DO NOT USE** to bypass protection on files you don't own or have no right to modify.

## Technical Details

### How Office Protection Works

Microsoft Office uses XML-based protection mechanisms:

1. **Presentation Lock (PowerPoint)**: Prevents modification without password
2. **Worksheet/Workbook Protection (Excel)**: Locks cells, sheets, or entire workbook
3. **Document Restrictions (Word)**: Limits editing, formatting, or comments

These protections are stored as XML tags in the document's internal structure. This script simply removes those tags.

### Why This Works

Office 2007+ files use the Open XML format (ECMA-376), which is essentially a ZIP archive containing XML files. The protection is stored in plain XML, making it removable by editing the XML structure.

**Note**: This only works for *editing restrictions*, not for *encryption* or *password-protected files*.

## Troubleshooting

### "Error: Failed to extract ZIP"
- File may be corrupted
- File may be encrypted (script doesn't support encrypted files)
- Ensure you have write permissions in the folder

### "Error: presentation.xml not found"
- File may be in legacy binary format
- File structure may be non-standard
- Try opening and re-saving in Office first

### "Access denied" or "Permission denied"
- Close the file in Office before running script
- Ensure file isn't on a read-only network share
- Check folder permissions

### Script hangs or doesn't complete
- Large files may take 30-60 seconds
- Check if antivirus is scanning the file
- Try moving file to a local folder (not network drive)

## Advanced Usage

### Batch Processing Multiple Files

Create a wrapper script:
```batch
@echo off
for %%F in (*.docx) do (
    call remove-office-protection.bat "%%F"
)
```

### Viewing Protection Tags Before Removal

1. Rename `.docx` to `.zip`
2. Extract the ZIP
3. Open the XML files in Notepad
4. Search for "protection" or "verifier"

## Version History

- **v1.2** (Current) - Added all Office formats, legacy detection, better error messages
- **v1.1** - Added Excel and Word support
- **v1.0** - Initial PowerPoint-only release

## Contributing

Found a bug or have a feature request? Please open an issue on the GitHub repository.

## License

This tool is provided as-is for legitimate personal and business use. Use responsibly.

## Acknowledgments

Based on the Open XML format specification (ECMA-376).
