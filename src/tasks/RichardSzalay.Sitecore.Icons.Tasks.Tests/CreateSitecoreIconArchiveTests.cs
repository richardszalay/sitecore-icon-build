using Microsoft.Build.Framework;
using Microsoft.Build.Utilities;
using System;
using System.Collections.Generic;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Xml;
using Xunit;

namespace RichardSzalay.Sitecore.Icons.Tasks.Tests
{
    public class CreateSitecoreIconArchiveTests
    {
        [Fact]
        public void NoEntries_ReturnsFalse()
        {
            TestArchiveTask(false, new ITaskItem[0]);
        }

        [Fact]
        public void ValidEntries_CreatesArchive()
        {
            TestArchiveTask(
                true,
                new[]
                {
                    CreateEntryItem(Path.GetTempFileName(), "fileA"),
                    CreateEntryItem(Path.GetTempFileName(), "fileB")
                });
        }


        static ITaskItem CreateEntryItem(string filename, string entryPath)
        {
            var taskItem = new TaskItem(filename);
            taskItem.SetMetadata("EntryPath", entryPath);

            return taskItem;
        }

        static void TestArchiveTask(bool expectedResult, ITaskItem[] entries)
        {
            var task = new CreateSitecoreIconArchive();

            var outputFile = Path.GetTempFileName();

            try
            {

                task.Entries = entries;

                task.Output = outputFile;

                task.BuildEngine = new FakeBuildEngine();

                var result = task.Execute();

                Assert.Equal(expectedResult, result);

                if (expectedResult)
                {
                    var expectedOutput = entries.Select(x => x.GetMetadata("EntryPath"));
                    var actual = GetArchiveEntries(outputFile);

                    Assert.Equal(expectedOutput.OrderBy(x => x), actual.OrderBy(x => x));
                }
            }
            finally
            {
                foreach (var entry in entries)
                {
                    try
                    {
                        File.Delete(entry.GetMetadata("FullPath"));
                    }
                    catch
                    {
                    }
                }

                try
                {
                    File.Delete(outputFile);
                }
                catch
                {

                }
            }
        }

        static string CreateTempFile(string contents)
        {
            var filename = Path.GetTempFileName();
            File.WriteAllText(filename, contents);
            return filename;
        }

        static string[] GetArchiveEntries(string filename)
        {
            using (var fileStream = new FileStream(filename, FileMode.Open))
            {
                using (var archive = new ZipArchive(fileStream, ZipArchiveMode.Read))
                {
                    return archive.Entries.Select(e => e.FullName).ToArray();
                }
            }
        }
    }
}
