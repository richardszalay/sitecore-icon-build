using Microsoft.Build.Framework;
using Microsoft.Build.Utilities;
using System;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Xml;

namespace RichardSzalay.Sitecore.Icons.Tasks
{
    public class CreateSitecoreIconArchive : Task
    {
        [Required]
        public ITaskItem[] Entries { get; set; }
        
        [Required]
        public string Output { get; set; }

        public override bool Execute()
        {
            if (Entries == null || Entries.Length == 0)
            {
                Log.LogError("No entries were supplied");
                return false;
            }

            try
            {
                const int BufferSize = 64 * 1024;

                var buffer = new byte[BufferSize];

                using (var outputFileStream = new FileStream(Output, FileMode.Create))
                {
                    using (var archive = new ZipArchive(outputFileStream, ZipArchiveMode.Create))
                    {
                        foreach (var inputFileName in Entries)
                        {
                            var inputFileFullPath = inputFileName.GetMetadata("FullPath");
                            var inputFileEntryPath = inputFileName.GetMetadata("EntryPath");

                            var archiveEntry = archive.CreateEntry(inputFileEntryPath);

                            using (var fs = new FileStream(inputFileFullPath, FileMode.Open))
                            {
                                using (var zipStream = archiveEntry.Open())
                                {
                                    int bytesRead = -1;
                                    while ((bytesRead = fs.Read(buffer, 0, BufferSize)) > 0)
                                    {
                                        zipStream.Write(buffer, 0, bytesRead);
                                    }
                                }
                            }
                        }
                    }
                }

                return true;
            }
            catch (Exception ex)
            {
                Log.LogErrorFromException(ex);
                return false;
            }
        }
    }
}
