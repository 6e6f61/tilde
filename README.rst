Tilde
=======
Cross-platform "POSIX" tilde expansion.

There are a few semantic notes in a source comment.

-------
Example
-------

.. code-block:: zig

    const std = @import("std");
    const tilde = @import("tilde.zig");
    
    pub fn main() !void {
        var out_buffer: [std.fs.MAX_PATH_BYTES]u8 = undefined;
        const expanded = try tilde.expand("~/.config", &out_buffer);
        
        std.debug.print("{s}", .{ expanded });
        // Output: either /home/<x>/.config or C:\Users\<x>\.config
    }
