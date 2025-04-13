# LICENSE NOTICE

## Incompatibility of Xilinx/Altera FPGA cores with GPL3

I regret to inform that **no FPGA core incorporating intellectual property (IP) from Xilinx or Altera can be licensed under GPL3**. This is due to fundamental incompatibilities between the license terms of these IPs and the requirements of the GNU General Public License version 3 (GPL3).

## Alert! The Great GPL3 Hoax in MiST, MiSTer and derivatives

Well, well, well! Here comes the fun part: **practically ALL cores for MiST, MiSTer and derivatives that are cheerfully labeled as "GPL3" are flagrantly violating this license** 😅

Yes, you read that right. No matter how much their authors insist with great conviction and proudly place the "GPL3" stamp on their repositories, they are in what we might politely call a... "massive conceptual error."

Why? It's simple: these cores use Altera/Intel IP (in both MiSTer and MiST cases) or Xilinx IP (in projects like zxUNO, zxDOS, zxTRES, etc.), which come with their own restrictive licenses. It's like trying to mix water and oil, and then insisting you've created pure water. It doesn't work that way, no matter how much one wishes it were true.

Imagine trying to build a "100% eco-friendly" building using radioactive materials. You can put the prettiest green certificate on the facade, but that doesn't change the physical reality. The same goes for these "GPL3" cores containing proprietary IP - the label doesn't change the fundamental incompatibility.

So the next time you see a MiST/MiSTer core labeled as GPL3, you can smile knowingly, aware that you're looking at the licensing equivalent of a unicorn: nice to imagine, impossible in reality.

### Reasons for incompatibility

1. **Redistribution restrictions**: Altera/Intel and Xilinx/AMD IP licenses impose restrictions on the redistribution of their components that directly conflict with the GPL3's freedom of redistribution clause.

2. **Fundamental freedoms**: GPL3 guarantees four essential freedoms:
   - The freedom to use the program for any purpose
   - The freedom to study and modify the source code
   - The freedom to redistribute copies
   - The freedom to distribute modified versions

   Altera/Intel and Xilinx/AMD IP licenses restrict some of these freedoms.

3. **GPL3 viral effect**: GPL3 requires that any derivative work incorporating GPL3 code must also be distributed under GPL3 or a compatible license. FPGA IP licenses are proprietary and not compatible with this requirement.

4. **Additional restrictions**: Section 7 of GPL3 prohibits imposing additional restrictions beyond those established in GPL3 itself. FPGA IP licenses impose additional incompatible restrictions.

5. **Impossibility of simultaneous compliance**: It is technically impossible to simultaneously comply with the terms of Altera/Intel or Xilinx/AMD IP licenses and GPL3, creating a situation of legal incompatibility.

### Licensing alternatives

For projects incorporating Altera/Intel or Xilinx/AMD IP, consider:

- More permissive licenses such as MIT, BSD, or Apache 2.0
- Dual licensing with specific exceptions for FPGA IP
- Hardware-specific licenses such as Solderpad or CERN OHL

### Important note

This document does not constitute legal advice. For important projects or those with complex legal considerations, it is recommended to consult with an attorney specializing in intellectual property and software/hardware licensing.

