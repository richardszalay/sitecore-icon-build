using Microsoft.Build.Framework;
using Microsoft.Build.Utilities;
using System;
using System.Collections.Generic;
using System.Drawing;
using System.IO;
using System.Linq;

namespace RichardSzalay.Sitecore.Icons.Tasks
{
    public class ResizeSitecoreIcons : Task
    {
        [Required]
        public ITaskItem[] UnsizedIcons { get; set; }

        [Required]
        public ITaskItem[] SizedIcons { get; set; }

        [Required]
        public string OutputSizes { get; set; }

        [Required]
        public string IntermediatePath { get; set; }

        [Output]
        public ITaskItem[] Output { get; set; }

        public override bool Execute()
        {
            if (UnsizedIcons == null || UnsizedIcons.Length == 0)
            {
                Log.LogError("No unsized icons were supplied");
                return false;
            }

            var outputList = new List<ITaskItem>();

            try
            {
                var outputDimensions = OutputSizes.Split(';'); //.Select(Dimensions.Parse);

                foreach (var unsizedIcon in UnsizedIcons)
                {
                    var unsizedIconPath = unsizedIcon.GetMetadata("FullPath");
                    var unsizedIconFile = new FileInfo(unsizedIconPath);

                    foreach (var outputDimension in outputDimensions)
                    {
                        var archiveName = unsizedIcon.GetMetadata("ArchiveName");
                        var filename = unsizedIcon.GetMetadata("Filename") + unsizedIcon.GetMetadata("Extension");

                        var entryPath = $"{archiveName}\\{outputDimension}\\{filename}";

                        if (SizedIconsInclude(SizedIcons, entryPath))
                        {
                            Log.LogMessage(MessageImportance.Low, 
                                "Skipped resize of {0} to {1} because an explicitly sized version was found",
                                unsizedIcon.ItemSpec, outputDimension);
                            continue;
                        }

                        string resizedIconPath = Path.Combine(IntermediatePath, entryPath);
                        var resizedIconFile = new FileInfo(resizedIconPath);

                        if (!IsSourceNewer(unsizedIconFile, resizedIconFile))
                        {
                            outputList.Add(new TaskItem(resizedIconFile.FullName, new Dictionary<string, string>
                            {
                                { "ArchiveName", archiveName },
                                { "EntryPath", entryPath }
                            }));

                            Log.LogMessage(MessageImportance.Low,
                                "Skipped resize of {0} to {1} because the source is not newer than the target",
                                unsizedIcon.ItemSpec, outputDimension);
                            continue;
                        }

                        try
                        {
                            var resizedIconDirectory = resizedIconFile.DirectoryName;

                            if (!Directory.Exists(resizedIconDirectory))
                                Directory.CreateDirectory(resizedIconDirectory);

                            Resize(unsizedIconFile, resizedIconFile, Dimensions.Parse(outputDimension));

                            outputList.Add(new TaskItem(resizedIconFile.FullName, new Dictionary<string, string>
                            {
                                { "ArchiveName", archiveName },
                                { "EntryPath", entryPath }
                            }));
                        }
                        catch(Exception ex)
                        {
                            //Log.LogErrorFromException(ex);
                            Log.LogError("Failed to resize image {0}", unsizedIcon);
                            continue;
                        }
                        
                    }
                }

                Output = outputList.ToArray();

                return true;
            }
            catch (Exception ex)
            {
                Log.LogErrorFromException(ex);
                return false;
            }
        }

        private void Resize(FileInfo unsizedIconFile, FileInfo resizedIconFile, Dimensions dimensions)
        {
            using (var unsizedFileStream = unsizedIconFile.OpenRead())
            using (var unsizedBitmap = Image.FromStream(unsizedFileStream))
            using (var sizedBitmap = new Bitmap(dimensions.Width, dimensions.Height))
            using (Graphics g = Graphics.FromImage(sizedBitmap))
            {
                if (WillUpscale(unsizedBitmap, dimensions))
                {
                    Log.LogWarning("Image {0} will be upscaled to {1}, resulting in a loss in quality. Replace the source with an image that is at least {1}.",
                        unsizedIconFile.FullName, dimensions.ToString());
                }

                g.DrawImage(unsizedBitmap, 0, 0, dimensions.Width, dimensions.Height);
                g.Flush();

                sizedBitmap.Save(resizedIconFile.FullName);
            }
        }

        private bool WillUpscale(Image unsizedBitmap, Dimensions dimensions)
        {
            return (dimensions.Width > unsizedBitmap.Width ||
                    dimensions.Height > unsizedBitmap.Height);
        }

        static bool IsSourceNewer(FileInfo source, FileInfo target)
        {
            if (!source.Exists)
            {
                throw new ArgumentException($"File {source.FullName} does not exist");
            }

            if (!target.Exists)
            {
                return true;
            }

            return source.LastWriteTimeUtc > target.LastWriteTimeUtc;
        }

        static bool SizedIconsInclude(ITaskItem[] sizedIcons, string entryPath)
        {
            if (sizedIcons == null || sizedIcons.Length == 0)
            {
                return false;
            }

            return sizedIcons.Select(i => i.GetMetadata("EntryPath")).Contains(entryPath);
        }

        struct Dimensions
        {
            public int Width;
            public int Height;

            public override string ToString()
            {
                return $"{Width}x{Height}";
            }

            public static Dimensions Parse(string input)
            {
                var parts = input.Split('x');

                if (parts.Length == 2 &&
                    int.TryParse(parts[0], out var width) &&
                    int.TryParse(parts[1], out var height))
                {
                    return new Dimensions
                    {
                        Width = width,
                        Height = height
                    };
                }

                throw new ArgumentException($"Invalid image dimensions: {input}. Expected [width]x[height]");
            }
        }
    }
}
